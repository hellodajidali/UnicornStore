import SwiftUI

@main
struct UnicornStoreWebApp: App {
    init() {
        // 诊断版：暂时不注册缓存协议，验证基础壳是否正常
        // OfflineURLProtocol.register()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
