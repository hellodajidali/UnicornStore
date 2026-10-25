import SwiftUI

@main
struct ChuanLinkApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @State private var target: URL? = nil
    @State private var hint: String = ""
    @State private var err: String = ""
    @State private var retryTick: Int = 0

    private static let SAVE_KEY = "chuan_last_url"

    init() {
        // iOS 会把后台挂着的 App 回收掉，重开时自动连上次的地址，不用重新扫码
        if let s = UserDefaults.standard.string(forKey: RootView.SAVE_KEY),
           let u = URL(string: s) {
            _target = State(initialValue: u)
        }
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            if let u = target {
                WebContainer(
                    url: u,
                    onFail: { msg in
                        // 关键：不清掉 target。地址留着，让用户点「重试」就行
                        err = msg
                    },
                    onRescan: {
                        err = ""
                        target = nil
                        UserDefaults.standard.removeObject(forKey: RootView.SAVE_KEY)
                    }
                )
                .id(retryTick)          // 点重试时整块重建，等于重新加载
                .edgesIgnoringSafeArea(.all)

                if !err.isEmpty {
                    errorCard
                }
            } else {
                ScannerView(hint: hint) { code in
                    guard let raw = URL(string: code.trimmingCharacters(in: .whitespacesAndNewlines)),
                          let scheme = raw.scheme?.lowercased(),
                          scheme == "http" || scheme == "https" else {
                        hint = "这个二维码不是互传的地址，换一个试试"
                        return
                    }
                    hint = ""
                    err = ""
                    let u = withDevice(raw)
                    UserDefaults.standard.set(u.absoluteString, forKey: RootView.SAVE_KEY)
                    target = u
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
    }

    /// 连不上时盖在页面上的提示卡片：重试 / 重新扫码
    private var errorCard: some View {
        VStack(spacing: 14) {
            Text("连不上电脑")
                .font(.headline)
                .foregroundColor(.white)
            Text(err)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 18)
            HStack(spacing: 12) {
                Button(action: {
                    err = ""
                    retryTick += 1
                }) {
                    Text("重试")
                        .font(.system(size: 16, weight: .medium))
                        .frame(minWidth: 84)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.03, green: 0.76, blue: 0.38))
                        .foregroundColor(.white)
                        .cornerRadius(11)
                }
                Button(action: {
                    err = ""
                    target = nil
                    UserDefaults.standard.removeObject(forKey: RootView.SAVE_KEY)
                }) {
                    Text("重新扫码")
                        .font(.system(size: 16, weight: .medium))
                        .frame(minWidth: 84)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.16))
                        .foregroundColor(.white)
                        .cornerRadius(11)
                }
            }
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 28)
        .background(Color.black.opacity(0.93))
        .cornerRadius(18)
        .padding(.horizontal, 30)
    }

    /// 手机这边固定一个设备号：程序每次重启换域名也不会让历史消息左右错位
    private var deviceId: String {
        let key = "chuan_device_id"
        if let s = UserDefaults.standard.string(forKey: key), s.count == 32 {
            return s
        }
        let s = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        UserDefaults.standard.set(s, forKey: key)
        return s
    }

    private func withDevice(_ u: URL) -> URL {
        guard var c = URLComponents(url: u, resolvingAgainstBaseURL: false) else { return u }
        var items = c.queryItems ?? []
        if !items.contains(where: { $0.name == "d" }) {
            items.append(URLQueryItem(name: "d", value: deviceId))
        }
        // app=1：告诉电脑"这是装了我自己 App 的设备"，给它主人权限
        if !items.contains(where: { $0.name == "app" }) {
            items.append(URLQueryItem(name: "app", value: "1"))
        }
        c.queryItems = items
        return c.url ?? u
    }
}
