import SwiftUI

// MARK: - 公告栏视图（自适应高度、无边框线）

struct AnnouncementView: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        let announcement = dataStore.storeData.announcement
        let text = announcement.text
        let isEmpty = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if isEmpty {
            Color.clear.frame(height: 0)
        } else {
            HStack(spacing: 8) {
                // 滚动的公告文字（已去掉小喇叭图标）
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(text)
                        .font(.system(size: announcement.fontSize))
                        .foregroundColor(announcement.textColor.toColor())
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                dataStore.storeData.announcementBgColor.toColor()
            )
            .cornerRadius(8)
        }
    }
}

// MARK: - 公告栏编辑视图（管理后台用）

struct AnnouncementEditView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var announcementText: String = ""
    @State private var fontSize: CGFloat = 14
    @State private var textColor: String = "#663399"
    @State private var showColorPicker = false
    @State private var announcementBgColor: String = "#F0F0F0"
    
    private let presetColors = ["#663399", "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#FF8C00", "#20B2AA", "#FF69B4", "#000000", "#808080"]
    
    var body: some View {
        Section(header: Text("公告栏").font(.headline)) {
            VStack(alignment: .leading, spacing: 8) {
                Text("公告内容（自动调整高度）：")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextEditor(text: $announcementText)
                    .frame(minHeight: 60)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onAppear {
                        announcementText = dataStore.storeData.announcement.text
                        fontSize = dataStore.storeData.announcement.fontSize
                        textColor = dataStore.storeData.announcement.textColor
                        announcementBgColor = dataStore.storeData.announcementBgColor
                    }
                
                // 字体大小
                VStack(alignment: .leading, spacing: 4) {
                    Text("字体大小：\(Int(fontSize))")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Slider(value: $fontSize, in: 10...28, step: 1)
                }
                
                // 字体颜色
                VStack(alignment: .leading, spacing: 4) {
                    Text("字体颜色：")
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack(spacing: 8) {
                        ForEach(presetColors, id: \.self) { color in
                            Circle()
                                .fill(color.toColor())
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(textColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    textColor = color
                                }
                        }
                    }
                }
                
                // 背景颜色切换（灰/白）
                VStack(alignment: .leading, spacing: 6) {
                    Text("背景颜色：")
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack(spacing: 12) {
                        Button(action: { announcementBgColor = "#F0F0F0" }) {
                            HStack {
                                Image(systemName: announcementBgColor == "#F0F0F0" ? "circle.fill" : "circle")
                                    .foregroundColor(Color(white: 0.8))
                                Text("浅灰")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.primary)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Button(action: { announcementBgColor = "#FFFFFF" }) {
                            HStack {
                                Image(systemName: announcementBgColor == "#FFFFFF" ? "circle.fill" : "circle")
                                    .foregroundColor(Color(white: 0.9))
                                Text("白色")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.primary)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        // 预览色块
                        RoundedRectangle(cornerRadius: 4)
                            .fill(announcementBgColor.toColor())
                            .frame(width: 28, height: 20)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.3)))
                    }
                }
            }
            .padding(.vertical, 4)
            
            Button("保存公告") {
                dataStore.storeData.announcement.text = announcementText
                dataStore.storeData.announcement.fontSize = fontSize
                dataStore.storeData.announcement.textColor = textColor
                dataStore.storeData.announcementBgColor = announcementBgColor
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(dataStore.storeData.themeColor.toColor())
            .cornerRadius(10)
        }
    }
}
