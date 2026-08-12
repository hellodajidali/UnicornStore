import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        WebViewContainer()
            .edgesIgnoringSafeArea(.all)
    }
}

struct WebViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .white
        webView.scrollView.bounces = true
        // 加载后台管理端（离线缓存协议会在首次加载后缓存全部内容）
        if let url = URL(string: "https://www.youwutu.top/houtai") {
            webView.load(URLRequest(url: url))
        }
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
