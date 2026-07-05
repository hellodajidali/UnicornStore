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
                
                // 2. 分类栏 — 独立在垂直 ScrollView 外面，避免手势竞争
                CategoryRowView(selectedId: $selectedCategoryId)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        // 1. 公告栏（稍微往下移一点）
                        AnnouncementView()
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                        
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
            .onAppear {
                if selectedCategoryId == nil {
                    selectedCategoryId = dataStore.storeData.categories.first?.id
                }
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
            
            // 显示/隐藏价格开关
            Button(action: {
                dataStore.storeData.showPrice.toggle()
            }) {
                Image(systemName: dataStore.storeData.showPrice ? "eye.fill" : "eye.slash.fill")
                    .font(.system(size: 16))
                    .foregroundColor(dataStore.storeData.showPrice ? themeColor : .gray)
                    .frame(width: 36, height: 36)
                    .background(themeColor.opacity(0.1))
                    .cornerRadius(18)
            }
            
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

// MARK: - 毛玻璃背景（iOS 14+ 兼容）

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - 图片放大覆盖层

struct ImageDetailOverlay: View {
    let product: Product?
    @Binding var isShowing: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    /// 保留商品数据，让关闭动画期间图片不会突然消失
    @State private var retainedProduct: Product? = nil
    
    var body: some View {
        ZStack {
            // 始终渲染 ZStack，用 opacity 控制显隐，避免条件渲染导致的闪现问题
            if isShowing || retainedProduct != nil {
                // 毛玻璃背景（单点关闭），关闭时像雾气散开无暗闪
                BlurView(style: .systemUltraThinMaterial)
                    .ignoresSafeArea()
                    .opacity(isShowing ? 1 : 0)
                    .onTapGesture(perform: dismiss)
                
                VStack(spacing: 12) {
                    // 关闭按钮
                    HStack {
                        Spacer()
                        Button(action: dismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 商品图片（优先用 retainedProduct 保证关闭动画期间图片不消失）
                    if let image = (retainedProduct ?? product)?.image {
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
                            .onTapGesture(count: 2, perform: dismiss)
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
                    if let p = retainedProduct ?? product {
                        VStack(spacing: 6) {
                            Text(p.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            if DataStore.shared.storeData.showPrice {
                                Text(p.price)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            
                            if !p.description.isEmpty {
                                Text(p.description)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    // 操作提示
                    Text("双击返回网格列表")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.6))
                        .padding(.top, 8)
                }
                .opacity(isShowing ? 1 : 0)
            }
        }
        // 不用 .animation() 修饰符，由 dismiss() 内部 withAnimation 控制动画时长
        // 打开 0.3s（来自 MainContentView 的 onEnlarge）, 关闭 0.15s（来自 dismiss()）
        .allowsHitTesting(isShowing)
        .onChange(of: isShowing) { newValue in
            if newValue {
                // 打开时：保留当前商品数据
                retainedProduct = product
            } else {
                // 关闭时：等 0.15s 动画彻底结束后再释放数据
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if !isShowing {
                        retainedProduct = nil
                    }
                }
            }
        }
        .onAppear {
            if isShowing {
                retainedProduct = product
            }
        }
    }
    
    private func dismiss() {
        // 关闭动画 0.15s，比打开快一倍，来不及感觉"画面一黑"
        withAnimation(.easeInOut(duration: 0.15)) {
            isShowing = false
            scale = 1.0
            lastScale = 1.0
        }
    }
    
}
