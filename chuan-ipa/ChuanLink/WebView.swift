import SwiftUI
import WebKit
import Photos

struct WebContainer: UIViewRepresentable {
    let url: URL
    let onFail: (String) -> Void
    let onRescan: () -> Void

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.dataDetectorTypes = []
        let uc = WKUserContentController()
        uc.add(context.coordinator, name: "saveImage")
        uc.add(context.coordinator, name: "rescan")
        config.userContentController = uc

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = context.coordinator
        wv.uiDelegate = context.coordinator
        wv.isOpaque = false
        wv.backgroundColor = .systemBackground
        wv.allowsBackForwardNavigationGestures = false
        wv.scrollView.contentInsetAdjustmentBehavior = .never
        wv.scrollView.bounces = false

        context.coordinator.webView = wv
        context.coordinator.load(url)
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> WebCoordinator {
        let c = WebCoordinator()
        c.onFail = onFail
        c.onRescan = onRescan
        return c
    }
}

final class WebCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    weak var webView: WKWebView?
    var onFail: ((String) -> Void)?
    var onRescan: (() -> Void)?

    private var startURL: URL?
    private var retries = 0

    func load(_ url: URL) {
        startURL = url
        retries = 0
        webView?.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 30))
    }

    // MARK: - JS 消息

    func userContentController(_ uc: WKUserContentController,
                              didReceive message: WKScriptMessage) {
        if message.name == "saveImage", let src = message.body as? String {
            saveImage(src)
        } else if message.name == "rescan" {
            onRescan?()
        }
    }

    /// 把图存进相册（网页里点"保存图片"走这里）
    private func saveImage(_ src: String) {
        guard let base = webView?.url,
              let u = URL(string: src, relativeTo: base) else { return }
        var req = URLRequest(url: u, cachePolicy: .reloadIgnoringLocalCacheData,
                             timeoutInterval: 30)
        req.setValue("Mozilla/5.0 (iPhone)", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let data = data, let img = UIImage(data: data) else {
                DispatchQueue.main.async { self?.toast("图片下载失败") }
                return
            }
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    DispatchQueue.main.async {
                        self?.toast("没有相册权限，去设置里打开")
                    }
                    return
                }
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: img)
                }, completionHandler: { ok, _ in
                    DispatchQueue.main.async {
                        self?.toast(ok ? "已保存到相册" : "保存失败")
                    }
                })
            }
        }.resume()
    }

    // MARK: - 网页里的 alert / confirm（不实现的话 confirm 会卡住）

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "好", style: .default) { _ in completionHandler() })
        topVC()?.present(a, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in completionHandler(false) })
        a.addAction(UIAlertAction(title: "确定", style: .destructive) { _ in completionHandler(true) })
        topVC()?.present(a, animated: true)
    }

    // MARK: - 加载失败重试

    private func retryOrFail() {
        guard let u = startURL else { return }
        if retries < 2 {
            retries += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self = self else { return }
                self.webView?.load(URLRequest(url: u, cachePolicy: .reloadIgnoringLocalCacheData,
                                              timeoutInterval: 30))
            }
        } else {
            onFail?("连不上电脑。可能程序关了，或者电脑那边重启过地址变了，重新扫一次码")
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        let ns = error as NSError
        if ns.code == NSURLErrorCancelled { return }
        retryOrFail()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let ns = error as NSError
        if ns.code == NSURLErrorCancelled { return }
        retryOrFail()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        retries = 0
    }

    // MARK: - 小提示

    private func toast(_ text: String) {
        guard let win = keyWindow() else { return }
        let l = UILabel()
        l.text = text
        l.textColor = .white
        l.font = .systemFont(ofSize: 14)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.backgroundColor = UIColor.black.withAlphaComponent(0.78)
        l.layer.cornerRadius = 12
        l.clipsToBounds = true
        l.alpha = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        win.addSubview(l)
        NSLayoutConstraint.activate([
            l.centerXAnchor.constraint(equalTo: win.centerXAnchor),
            l.bottomAnchor.constraint(equalTo: win.safeAreaLayoutGuide.bottomAnchor, constant: -90),
            l.widthAnchor.constraint(lessThanOrEqualTo: win.widthAnchor, multiplier: 0.7),
            l.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
        UIView.animate(withDuration: 0.2) { l.alpha = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            UIView.animate(withDuration: 0.3, animations: { l.alpha = 0 }) { _ in
                l.removeFromSuperview()
            }
        }
    }

    private func keyWindow() -> UIWindow? {
        if #available(iOS 15.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        }
        return UIApplication.shared.windows.first { $0.isKeyWindow }
    }

    private func topVC() -> UIViewController? {
        var vc = keyWindow()?.rootViewController
        while let p = vc?.presentedViewController { vc = p }
        return vc
    }
}
