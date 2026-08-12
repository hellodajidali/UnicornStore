import SwiftUI
import WebKit
import Network

struct ContentView: View {
    @State private var reloadToken = UUID()
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            WebViewContainer(reloadToken: reloadToken)
                .edgesIgnoringSafeArea(.all)
            // 刷新按钮（右下角浮动，可随时重新加载）
            Button {
                reloadToken = UUID()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color(red: 1.0, green: 0.35, blue: 0.0)))
                    .shadow(color: .black.opacity(0.25), radius: 5, x: 0, y: 2)
            }
            .padding(.trailing, 18)
            .padding(.bottom, 40)
        }
    }
}

/// 控制器：在线加载后台 + 收集数据/页面缓存 + 断网时本地数据注入（页面交互完整可用）
class WebViewController: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    let webView: WKWebView
    private let monitor = NWPathMonitor()
    private var isOnline = true
    private let spinner = UIActivityIndicatorView(style: .gray)
    var lastToken = UUID()

    private var offlineDataURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("offline_data.json")
    }
    private var indexCacheURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("index_cache.html")
    }

    override init() {
        let config = WKWebViewConfiguration()
        let userContent = WKUserContentController()
        config.userContentController = userContent
        webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        userContent.add(self, name: "snapshot")
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .white
        spinner.translatesAutoresizingMaskIntoConstraints = false
        webView.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: webView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: webView.centerYAnchor)
        ])
        startNetworkMonitor()
    }

    func reload() { load() }

    func load() {
        if isOnline {
            webView.configuration.preferences.javaScriptEnabled = true
            if let url = URL(string: "https://www.youwutu.top/houtai") {
                webView.load(URLRequest(url: url))
            }
        } else {
            loadOffline()
        }
    }

    private func startNetworkMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = (path.status == .satisfied)
            DispatchQueue.main.async {
                guard let self = self else { return }
                let changed = (self.isOnline != online)
                self.isOnline = online
                if changed {
                    if online {
                        self.load()
                    } else {
                        self.loadOffline()
                    }
                }
            }
        }
        monitor.start(queue: DispatchQueue(label: "netmon"))
    }

    /// 断网：加载本地页面 + 注入本地数据（JS 正常运行，分类/按钮全部可用）
    private func loadOffline() {
        guard let html = try? String(contentsOf: indexCacheURL, encoding: .utf8) else {
            webView.loadHTMLString("<html><body style='text-align:center;padding-top:120px;color:#999;font-family:sans-serif'>无网络，且还没有缓存内容<br>请联网打开一次后再离线使用</body></html>", baseURL: nil)
            return
        }
        let dataStr: String
        if let d = try? String(contentsOf: offlineDataURL, encoding: .utf8) {
            dataStr = d
        } else {
            dataStr = "null"
        }
        webView.configuration.preferences.javaScriptEnabled = true
        // 注入本地数据（页面脚本执行前生效）
        webView.configuration.userContentController.removeAllUserScripts()
        let script = WKUserScript(
            source: "window.__OFFLINE_DATA__ = \(dataStr);",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        webView.configuration.userContentController.addUserScript(script)
        // baseURL 用根路径：离线以顾客端前台模式渲染（后台管理需联网）
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youwutu.top"))
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        spinner.startAnimating()
        spinner.isHidden = false
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        spinner.stopAnimating()
        spinner.isHidden = true
        // 保存页面 HTML（离线用）
        cacheCurrentPage()
        // 等数据渲染完，收集数据（adminData + 图片 base64）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.captureData()
        }
    }

    private func cacheCurrentPage() {
        guard isOnline, let url = URL(string: "https://www.youwutu.top") else { return }
        // Swift 直接下载原始 HTML（含全部 JS），离线时加载
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            if let data = data, let html = String(data: data, encoding: .utf8) {
                try? html.write(to: self?.indexCacheURL ?? URL(fileURLWithPath: "/dev/null"), atomically: true, encoding: .utf8)
            }
        }.resume()
    }

    /// 收集数据：adminData + 商品图片转 base64 → postMessage → 存沙盒
    private func captureData() {
        guard isOnline else { return }
        let js = """
        (async function(){
          try {
            const r = await fetch('/api/store');
            const j = await r.json();
            if (!j || !j.data) return;
            const prods = j.data.products || [];
            const pool = 6;
            for (let i = 0; i < prods.length; i += pool) {
              await Promise.all(prods.slice(i, i + pool).map(async (p) => {
                if (p.imageData && p.imageData.indexOf('img_') === 0) {
                  try {
                    const ir = await fetch('/api/image/' + p.imageData);
                    const b = await ir.blob();
                    p.imageData = await new Promise(res => { const fr = new FileReader(); fr.onload = () => res(fr.result); fr.readAsDataURL(b); });
                  } catch(e) {}
                }
              }));
            }
            window.webkit.messageHandlers.snapshot.postMessage(JSON.stringify(j.data));
          } catch(e) {}
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "snapshot", let str = message.body as? String {
            try? str.write(to: offlineDataURL, atomically: true, encoding: .utf8)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        spinner.stopAnimating(); spinner.isHidden = true
        if !isOnline { loadOffline() }
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        spinner.stopAnimating(); spinner.isHidden = true
        if !isOnline { loadOffline() }
    }
}

struct WebViewContainer: UIViewRepresentable {
    let reloadToken: UUID

    func makeUIView(context: Context) -> WKWebView {
        context.coordinator.load()
        return context.coordinator.webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if context.coordinator.lastToken != reloadToken {
            context.coordinator.lastToken = reloadToken
            context.coordinator.reload()
        }
    }
    func makeCoordinator() -> WebViewController {
        let c = WebViewController()
        c.lastToken = reloadToken
        return c
    }
}
