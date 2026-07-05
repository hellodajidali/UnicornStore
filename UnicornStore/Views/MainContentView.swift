import SwiftUI

// MARK: - 主界面

struct MainContentView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedCategoryId: UUID?
    @State private var showAdmin = false
    @State private var enlargedProduct: Product? = nil
    
    private var allCategoryId: UUID? {
        dataStore.storeData.categories.first?.id
    }
    
    private var themeColor: Color {
        dataStore.storeData.themeColor.toColor()
    }
    
    private var filteredProducts: [Product] {
        if selectedCategoryId == nil || selectedCategoryId == allCategoryId {
            return dataStore.storeData.products
        }
        return dataStore.storeData.products.filter { $0.categoryId == selectedCategoryId }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部工具栏
                topToolbar
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        // 1. 公告栏（稍微往下移一点）
                        AnnouncementView()
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                        
                        // 2. 分类栏
                        CategoryRowView(selectedId: $selectedCategoryId)
                            .padding(.horizontal, 12)
                        
                        // 3. 商品网格
                        ProductGridView(
                            products: filteredProducts,
                            onEnlarge: { product in
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    enlargedProduct = product
                                }
                            }
                        )
                        .padding(.horizontal, 12)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .overlay(
                // 图片放大覆盖层
                ImageDetailOverlay(
                    product: enlargedProduct,
                    isShowing: Binding(
                        get: { enlargedProduct != nil },
                        set: { if !$0 { enlargedProduct = nil } }
                    )
                )
            )
            .sheet(isPresented: $showAdmin) {
                AdminPanelView()
                    .environmentObject(dataStore)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - 顶部工具栏
    private var topToolbar: some View {
        HStack {
            Text(dataStore.storeData.storeName)
                .font(.system(size: dataStore.storeData.storeNameFontSize, weight: .bold))
                .foregroundColor(dataStore.storeData.storeNameColor.toColor())
            
            Spacer()
            
            Button(action: {
                showAdmin = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "gear")
                        .font(.system(size: 16))
                    Text("管理")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(themeColor)
                .cornerRadius(20)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 2)
    }
}

// MARK: - 图片放大覆盖层

struct ImageDetailOverlay: View {
    let product: Product?
    @Binding var isShowing: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            if isShowing, let product = product {
                // 半透明背景（单点关闭）
                Color.black.opacity(0.9)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowing = false
                            scale = 1.0
                            lastScale = 1.0
                        }
                    }
                
                VStack(spacing: 12) {
                    // 关闭按钮
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isShowing = false
                                scale = 1.0
                                lastScale = 1.0
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 商品图片
                    if let image = product.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let newScale = lastScale * value
                                        scale = min(max(newScale, 0.5), 4.0)
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                    }
                            )
                            .onTapGesture(count: 2) {
                                handleDoubleTap()
                            }
                            .frame(maxWidth: UIScreen.main.bounds.width - 40)
                            .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 200, height: 200)
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // 商品信息
                    VStack(spacing: 6) {
                        Text(product.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        if DataStore.shared.storeData.showPrice {
                            Text(product.price)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.orange)
                        }
                        
                        if !product.description.isEmpty {
                            Text(product.description)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        }
                    }
                    
                    // 操作提示
                    Text(scale > 1.0 ? "双击缩小" : "双击放大")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.top, 8)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isShowing)
    }
    
    private func handleDoubleTap() {
        withAnimation(.spring()) {
            if scale > 1.0 {
                // 已放大 → 缩小回默认
                scale = 1.0
                lastScale = 1.0
            } else {
                // 默认大小 → 放大到2.5倍
                scale = 2.5
                lastScale = 2.5
            }
        }
    }
}
