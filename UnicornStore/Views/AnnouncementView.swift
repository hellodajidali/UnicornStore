import SwiftUI

// MARK: - 公告栏视图（自适应高度、无边框线）

struct AnnouncementView: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        let text = dataStore.storeData.announcement.text
        let isEmpty = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if isEmpty {
            // 无公告时显示很小的占位
            Color.clear.frame(height: 0)
        } else {
            HStack(spacing: 8) {
                // 公告图标
                Image(systemName: "megaphone.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.6))
                    .frame(width: 20)
                
                // 滚动的公告文字
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(text)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.4, green: 0.15, blue: 0.5))
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                // scrollDisabled requires iOS 16+, skipped for iOS 14 compat
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Color(red: 0.95, green: 0.9, blue: 0.98)
            )
            .cornerRadius(8)
        }
    }
}

// MARK: - 公告栏编辑视图（管理后台用）

struct AnnouncementEditView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var announcementText: String = ""
    
    var body: some View {
        Section(header: Text("公告栏").font(.headline)) {
            VStack(alignment: .leading, spacing: 8) {
                Text("公告内容（自动调整高度，无边框线）：")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextEditor(text: $announcementText)
                    .frame(minHeight: 60)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onAppear {
                        announcementText = dataStore.storeData.announcement.text
                    }
            }
            .padding(.vertical, 4)
            
            Button("保存公告") {
                dataStore.storeData.announcement.text = announcementText
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(red: 0.6, green: 0.2, blue: 0.6))
            .cornerRadius(10)
        }
    }
}
