import SwiftUI
import WebKit
import Network

struct ContentView: View {
    var body: some View {
        WebViewContainer()
            .edgesIgnoringSafeArea(.all)
    }
}

/// 控制器：在线加载后台 + 自动保存页面快照 + 断网时显示快照（离线可用）
class WebViewController: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    let webView: WKWebView
    private let monitor = NWPathMonitor()
    private var isOnline = true

    private var snapshotURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("snapshot.html")
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
        startNetworkMonitor()
    }

    func load() {
        if isOnline {
            webView.configuration.preferences.javaScriptEnabled = true
            if let url = URL(string: "https://www.youwutu.top/houtai") {
                webView.load(URLRequest(url: url))
            }
        } else {
            loadSnapshot()
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
                        self.load()          // 恢复网络：重新加载在线页面并更新快照
                    } else {
                        self.loadSnapshot()  // 断网：显示最后快照
                    }
                }
            }
        }
        monitor.start(queue: DispatchQueue(label: "netmon"))
    }

    private func loadSnapshot() {
        guard let html = try? String(contentsOf: snapshotURL, encoding: .utf8) else {
            // 无快照（从未在线加载过）：显示提示
            webView.loadHTMLString("<html><body style='text-align:center;padding-top:120px;color:#999;font-family:sans-serif'>无网络，且还没有缓存内容<br>请联网打开一次后再离线使用</body></html>", baseURL: nil)
            return
        }
        // 关闭 JS 防止快照页面重新执行脚本清空内容
        webView.configuration.preferences.javaScriptEnabled = false
        webView.loadHTMLString(html, baseURL: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // 页面加载完成：等数据渲染完，保存快照（图片转 base64 内嵌）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.captureSnapshot()
        }
    }

    private func captureSnapshot() {
        guard isOnline else { return }
        let js = """
        (async function(){
          try {
            const imgs = Array.from(document.querySelectorAll('img'));
            // 并发分批转换（每批6张），避免串行太慢
            const pool = 6;
            for (let i = 0; i < imgs.length; i += pool) {
              const batch = imgs.slice(i, i + pool);
              await Promise.all(batch.map(async (img) => {
                try {
                  const r = await fetch(img.src);
                  const b = await r.blob();
                  img.src = await new Promise(res => { const fr = new FileReader(); fr.onload = () => res(fr.result); fr.readAsDataURL(b); });
                } catch(e) {}
              }));
            }
            window.webkit.messageHandlers.snapshot.postMessage(document.documentElement.outerHTML);
          } catch(e) {}
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "snapshot", let html = message.body as? String {
            try? html.write(to: snapshotURL, atomically: true, encoding: .utf8)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if !isOnline { loadSnapshot() }
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if !isOnline { loadSnapshot() }
    }
}

struct WebViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        context.coordinator.load()
        return context.coordinator.webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    func makeCoordinator() -> WebViewController { WebViewController() }
}
