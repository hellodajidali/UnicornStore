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

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            if let u = target {
                WebContainer(
                    url: u,
                    onFail: { msg in
                        hint = msg
                        target = nil
                    },
                    onRescan: {
                        hint = ""
                        target = nil
                    }
                )
                .edgesIgnoringSafeArea(.all)
            } else {
                ScannerView(hint: hint) { code in
                    guard let raw = URL(string: code.trimmingCharacters(in: .whitespacesAndNewlines)),
                          let scheme = raw.scheme?.lowercased(),
                          scheme == "http" || scheme == "https" else {
                        hint = "这个二维码不是互传的地址，换一个试试"
                        return
                    }
                    hint = ""
                    target = withDevice(raw)
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
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
        c.queryItems = items
        return c.url ?? u
    }
}
