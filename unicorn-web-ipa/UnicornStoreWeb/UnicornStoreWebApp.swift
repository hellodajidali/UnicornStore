import SwiftUI

@main
struct UnicornStoreWebApp: App {
    init() {
        // 注册离线缓存协议（拦截 https 请求，缓存页面/图片/数据）
        OfflineURLProtocol.register()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
