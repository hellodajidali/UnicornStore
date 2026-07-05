import SwiftUI

// MARK: - 主界面

struct MainContentView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedCategoryId: UUID?
    @State private var showAdmin = false
    @State private var enlargedProduct: Product? = nil
    @State private var showImageDetail = false
    
    private var allCategoryId: UUID? {
        dataStore.storeData.categories.first?.id
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
                        // 1. 顶部横幅
                        TopBannerView()
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                        
                        // 2. 公告栏
                        AnnouncementView()
                            .padding(.horizontal, 12)
                        
                        // 3. 分类栏
                        CategoryRowView(selectedId: $selectedCategoryId)
                            .padding(.horizontal, 12)
                        
                        // 4. 商品网格
                        ProductGridView(
                            products: filteredProducts,
                            enlargedProduct: $enlargedProduct
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
            Text("独角商店")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.6))
            
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
                .background(Color(red: 0.6, green: 0.2, blue: 0.6))
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
                // 半透明背景
                Color.black.opacity(0.9)
                    .ignoresSafeArea()
                    .onTapGesture(count: 2) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowing = false
                            scale = 1.0
                        }
                    }
                
                VStack(spacing: 12) {
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
                                withAnimation(.spring()) {
                                    if scale > 1.0 {
                                        scale = 1.0
                                        lastScale = 1.0
                                    } else {
                                        scale = 2.5
                                        lastScale = 2.5
                                    }
                                }
                            }
                            .frame(maxWidth: UIScreen.main.bounds.width - 40)
                            .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
                    } else {
                        // 无图片时的占位
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
                    
                    // 关闭提示
                    Text("双击图片关闭")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.top, 8)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isShowing)
    }
}
