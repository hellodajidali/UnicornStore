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
        uc.add(context.coordinator, name: "saveMedia")
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

final class WebCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate,
                           WKScriptMessageHandler, URLSessionDownloadDelegate {
    weak var webView: WKWebView?
    var onFail: ((String) -> Void)?
    var onRescan: (() -> Void)?

    private var startURL: URL?
    private var retries = 0

    // 保存到相册用
    private var saveSession: URLSession?
    private var saving = false
    private var savingIsVideo = false
    private var savingIsImage = false
    private var savingExt = ""
    private var lastPct = -1

    func load(_ url: URL) {
        startURL = url
        retries = 0
        webView?.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 30))
    }

    // MARK: - JS 消息

    func userContentController(_ uc: WKUserContentController,
                              didReceive message: WKScriptMessage) {
        if message.name == "saveMedia", let src = message.body as? String {
            saveMedia(src)
        } else if message.name == "rescan" {
            onRescan?()
        }
    }

    /// 存图片或视频到相册（网页里点"保存"走这里）
    /// 用带 delegate 的 session，好显示下载进度，不然用户不知道在动
    private func saveMedia(_ src: String) {
        guard !saving else {
            toast("正在保存，稍等一下…")
            return
        }
        guard let base = webView?.url,
              let u = URL(string: src, relativeTo: base) else { return }

        let ext = u.pathExtension.lowercased()
        savingIsVideo = ["mp4", "mov", "webm", "3gp", "m4v"].contains(ext)
        savingIsImage = ["jpg", "jpeg", "png", "gif", "webp", "heic", "bmp"]
            .contains(ext)
        savingExt = ext
        saving = true
        lastPct = -1

        var req = URLRequest(url: u, cachePolicy: .reloadIgnoringLocalCacheData,
                             timeoutInterval: 180)
        req.setValue("Mozilla/5.0 (iPhone)", forHTTPHeaderField: "User-Agent")

        if savingIsVideo {
            toast("正在下载视频 0%", sticky: true)
        } else if savingIsImage {
            toast("正在保存…", sticky: true)
        } else {
            toast("正在下载文件 0%", sticky: true)
        }

        let session = URLSession(configuration: .default, delegate: self,
                                 delegateQueue: .main)
        saveSession = session
        session.downloadTask(with: req).resume()
    }

    /// 下载中：刷新百分比
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0, !savingIsImage else { return }
        let pct = Int(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100)
        guard pct != lastPct else { return }
        lastPct = pct
        let mb = Double(totalBytesExpectedToWrite) / 1048576.0
        let what = savingIsVideo ? "视频" : "文件"
        toast(String(format: "正在下载%@ %d%%  (%.1f MB)", what, pct, mb), sticky: true)
    }

    /// 下载完：立刻把文件挪走（这个回调一返回临时文件就没了）
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        let name = UUID().uuidString + "." +
            (savingExt.isEmpty ? (savingIsVideo ? "mp4" : "jpg") : savingExt)
        let dst = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: dst)
        do {
            try FileManager.default.moveItem(at: location, to: dst)
        } catch {
            finishSave("保存失败")
            return
        }
        if savingIsVideo || savingIsImage {
            toast("正在存入相册…", sticky: true)
            writeToAlbum(dst)
        } else {
            // 普通文件：弹系统分享面板，可以让用户"存储到文件"或发给别人
            shareFile(dst)
        }
    }

    private func shareFile(_ url: URL) {
        saving = false
        saveSession?.invalidateAndCancel()
        saveSession = nil
        hideToast()
        guard let vc = topVC() else { return }
        let act = UIActivityViewController(activityItems: [url],
                                           applicationActivities: nil)
        if let pop = act.popoverPresentationController {
            pop.sourceView = vc.view
            pop.sourceRect = CGRect(x: vc.view.bounds.midX,
                                    y: vc.view.bounds.maxY - 90,
                                    width: 1, height: 1)
            pop.permittedArrowDirections = []
        }
        vc.present(act, animated: true)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        guard let err = error else { return }
        let ns = err as NSError
        if ns.code == NSURLErrorCancelled { return }
        if saving { finishSave("下载失败，检查一下网络") }
    }

    private func writeToAlbum(_ dst: URL) {
        let isVideo = savingIsVideo
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            guard status == .authorized || status == .limited else {
                try? FileManager.default.removeItem(at: dst)
                DispatchQueue.main.async { self?.finishSave("没有相册权限，去设置里打开") }
                return
            }
            PHPhotoLibrary.shared().performChanges({
                if isVideo {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: dst)
                } else if let img = UIImage(contentsOfFile: dst.path) {
                    PHAssetChangeRequest.creationRequestForAsset(from: img)
                }
            }, completionHandler: { ok, _ in
                try? FileManager.default.removeItem(at: dst)
                DispatchQueue.main.async {
                    let what = isVideo ? "视频" : "图片"
                    self?.finishSave(ok ? "\(what)已存到相册" : "\(what)保存失败")
                }
            })
        }
    }

    private func finishSave(_ msg: String) {
        saving = false
        saveSession?.invalidateAndCancel()
        saveSession = nil
        toast(msg)
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

    private var toastLabel: UILabel?
    private var toastTimer: DispatchWorkItem?

    /// sticky=true 时不会自动消失，用来显示下载进度
    private func toast(_ text: String, sticky: Bool = false) {
        guard let win = keyWindow() else { return }
        let l: UILabel
        if let t = toastLabel, t.superview != nil {
            l = t
        } else {
            l = UILabel()
            l.textColor = .white
            l.font = .systemFont(ofSize: 14)
            l.textAlignment = .center
            l.numberOfLines = 0
            l.backgroundColor = UIColor.black.withAlphaComponent(0.82)
            l.layer.cornerRadius = 12
            l.clipsToBounds = true
            l.alpha = 0
            l.translatesAutoresizingMaskIntoConstraints = false
            win.addSubview(l)
            NSLayoutConstraint.activate([
                l.centerXAnchor.constraint(equalTo: win.centerXAnchor),
                l.bottomAnchor.constraint(equalTo: win.safeAreaLayoutGuide.bottomAnchor,
                                          constant: -90),
                l.widthAnchor.constraint(lessThanOrEqualTo: win.widthAnchor, multiplier: 0.72),
                l.heightAnchor.constraint(greaterThanOrEqualToConstant: 42)
            ])
            toastLabel = l
            UIView.animate(withDuration: 0.2) { l.alpha = 1 }
        }
        // UILabel 没有内边距，靠空格撑一下
        l.text = "  " + text + "  "
        toastTimer?.cancel()
        toastTimer = nil
        if !sticky {
            let work = DispatchWorkItem { [weak self] in self?.hideToast() }
            toastTimer = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: work)
        }
    }

    private func hideToast() {
        guard let l = toastLabel else { return }
        toastLabel = nil
        UIView.animate(withDuration: 0.3, animations: { l.alpha = 0 }) { _ in
            l.removeFromSuperview()
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
