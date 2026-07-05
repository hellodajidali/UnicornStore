import SwiftUI

// MARK: - 顶部横幅（可编辑文字或图片）

struct TopBannerView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showImagePicker = false
    
    var body: some View {
        let banner = dataStore.storeData.topBanner
        
        Group {
            if let image = banner.image {
                // 显示图片横幅
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 140)
                    .clipped()
                    .cornerRadius(12)
                    .overlay(
                        // 如果文字不为空，叠加文字
                        if !banner.text.isEmpty {
                            Text(banner.text)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 3)
                        }
                    )
            } else {
                // 纯文字横幅
                ZStack {
                    // 渐变背景
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.6, green: 0.2, blue: 0.6),
                            Color(red: 0.8, green: 0.3, blue: 0.7)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    
                    Text(banner.text)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .multilineTextAlignment(.center)
                }
                .frame(height: 100)
                .cornerRadius(12)
            }
        }
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
}

// MARK: - 顶部横幅编辑视图（管理后台用）

struct TopBannerEditView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var bannerText: String = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showActionSheet = false
    
    var body: some View {
        Section(header: Text("顶部横幅").font(.headline)) {
            VStack(alignment: .leading, spacing: 12) {
                Text("横幅文字：")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextField("输入横幅文字", text: $bannerText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onAppear {
                        bannerText = dataStore.storeData.topBanner.text
                    }
                
                HStack(spacing: 12) {
                    Button(action: {
                        showActionSheet = true
                    }) {
                        HStack {
                            Image(systemName: "photo.fill")
                            Text(dataStore.storeData.topBanner.image != nil ? "更换图片" : "添加图片")
                        }
                        .font(.system(size: 14))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    
                    if dataStore.storeData.topBanner.image != nil {
                        Button(action: {
                            dataStore.storeData.topBanner.imageData = nil
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("删除图片")
                            }
                            .font(.system(size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                        }
                    }
                }
                
                // 预览当前横幅
                if let img = dataStore.storeData.topBanner.image {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 100)
                        .clipped()
                        .cornerRadius(8)
                }
            }
            .padding(.vertical, 4)
            
            Button("保存横幅设置") {
                dataStore.storeData.topBanner.text = bannerText
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(red: 0.6, green: 0.2, blue: 0.6))
            .cornerRadius(10)
        }
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text("选择横幅图片"),
                buttons: [
                    .default(Text("从相册选择")) { showImagePicker = true },
                    .cancel(Text("取消"))
                ]
            )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(selectedImage: $selectedImage, onImagePicked: { image in
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    dataStore.storeData.topBanner.imageData = imageData
                }
            })
        }
    }
}
