import SwiftUI

@main
struct UnicornStoreApp: App {
    @StateObject private var dataStore = DataStore.shared
    @State private var showAdmin = false
    @State private var adminTapCount = 0
    
    var body: some Scene {
        WindowGroup {
            MainContentView()
                .environmentObject(dataStore)
                .onTapGesture(count: 3) {
                    // 连续点击顶部3次进入管理后台
                    // 实际通过导航栏按钮进入
                }
                .sheet(isPresented: $showAdmin) {
                    AdminPanelView()
                        .environmentObject(dataStore)
                }
        }
    }
}
