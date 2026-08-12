import Foundation
import CryptoKit

// ================= 离线缓存存储 =================
struct CacheEntry {
    let data: Data
    let headers: [String: String]
}

final class CacheStore {
    static let shared = CacheStore()
    private let fileManager = FileManager.default

    private var cacheDir: URL {
        let dir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("webcache", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func key(for url: URL) -> String {
        let data = Data(url.absoluteString.utf8)
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    func load(for url: URL) -> CacheEntry? {
        let k = key(for: url)
        let dataURL = cacheDir.appendingPathComponent(k)
        let metaURL = cacheDir.appendingPathComponent(k + ".meta")
        guard let data = try? Data(contentsOf: dataURL),
              let metaData = try? Data(contentsOf: metaURL),
              let meta = try? JSONDecoder().decode([String: String].self, from: metaData) else {
            return nil
        }
        return CacheEntry(data: data, headers: meta)
    }

    func save(_ data: Data, headers: [String: String], for url: URL) {
        let k = key(for: url)
        let dataURL = cacheDir.appendingPathComponent(k)
        let metaURL = cacheDir.appendingPathComponent(k + ".meta")
        try? data.write(to: dataURL)
        if let meta = try? JSONEncoder().encode(headers) {
            try? meta.write(to: metaURL)
        }
    }
}

// ================= 离线缓存 URLProtocol =================
/// 拦截 https 请求：缓存优先（离线可用）+ 后台刷新（联网时更新内容）
final class OfflineURLProtocol: URLProtocol {

    /// 专用 session：protocolClasses 清空，避免自己的请求被自己拦截（递归崩溃）
    private static let netSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = []
        return URLSession(configuration: config)
    }()

    static func register() {
        URLProtocol.registerClass(OfflineURLProtocol.self)
        // 私有 API：让 WKWebView 的 https 请求走 URLProtocol（TrollStore 环境可用）
        if let wkV = NSClassFromString("WKWebView") as? NSObject.Type {
            wkV.perform(NSSelectorFromString("registerSchemeForCustomProtocol"), with: "https")
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard let scheme = request.url?.scheme?.lowercased() else { return false }
        return scheme == "https" || scheme == "http"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    private var dataTask: URLSessionDataTask?

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        if let entry = CacheStore.shared.load(for: url) {
            // 缓存命中：立即返回（离线可用），后台刷新更新缓存
            let resp = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: entry.headers)
                ?? HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [:])!
            client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: entry.data)
            client?.urlProtocolDidFinishLoading(self)
            refresh(url: url)
        } else {
            fetch(url: url)
        }
    }

    private func fetch(url: URL) {
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 20
        dataTask = OfflineURLProtocol.netSession.dataTask(with: req) { [weak self] data, resp, err in
            guard let self = self else { return }
            if let data = data, let http = resp as? HTTPURLResponse, http.statusCode == 200 {
                CacheStore.shared.save(data, headers: self.headers(from: http), for: url)
            }
            if let d = data {
                let r = resp ?? HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [:])!
                self.client?.urlProtocol(self, didReceive: r, cacheStoragePolicy: .notAllowed)
                self.client?.urlProtocol(self, didLoad: d)
                self.client?.urlProtocolDidFinishLoading(self)
            } else {
                self.client?.urlProtocol(self, didFailWithError: err ?? URLError(.networkConnectionLost))
            }
        }
        dataTask?.resume()
    }

    /// 后台静默刷新缓存（有网时更新，失败不影响已返回的缓存）
    private func refresh(url: URL) {
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 15
        OfflineURLProtocol.netSession.dataTask(with: req) { data, resp, _ in
            guard let data = data, let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return }
            CacheStore.shared.save(data, headers: self.headers(from: http), for: url)
        }.resume()
    }

    private func headers(from resp: HTTPURLResponse) -> [String: String] {
        var h: [String: String] = [:]
        if let ct = resp.allHeaderFields["Content-Type"] as? String { h["Content-Type"] = ct }
        if let cc = resp.allHeaderFields["Cache-Control"] as? String { h["Cache-Control"] = cc }
        return h
    }

    override func stopLoading() {
        dataTask?.cancel()
    }
}
