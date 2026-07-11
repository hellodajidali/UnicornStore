import SwiftUI

// MARK: - 主界面

struct MainContentView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedCategoryId: UUID?
    @State private var showAdmin = false
    @State private var enlargedProduct: Product? = nil
    @State private var showQuoteAlert = false
    @State private var quoteAlertMessage = ""
    
    private var allCategoryId: UUID? {
        dataStore.storeData.categories.first?.id
    }
    
    private var themeColor: Color {
        dataStore.storeData.themeColor.toColor()
    }
    
    private var filteredProducts: [Product] {
        let activeProducts = dataStore.storeData.products.filter { $0.isActive }
        if selectedCategoryId == nil || selectedCategoryId == allCategoryId {
            return activeProducts
        }
        return activeProducts.filter { $0.categoryId == selectedCategoryId }
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
                                withAnimation(.easeInOut(duration: 0.15)) {
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
            .alert(isPresented: $showQuoteAlert) {
                Alert(title: Text("报价单"), message: Text(quoteAlertMessage), dismissButton: .default(Text("确定")))
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
            
            // 纯文字显示模式开关
            Button(action: {
                dataStore.storeData.showTextOnly.toggle()
            }) {
                Image(systemName: dataStore.storeData.showTextOnly ? "doc.text.fill" : "text.alignleft")
                    .font(.system(size: 16))
                    .foregroundColor(dataStore.storeData.showTextOnly ? themeColor : .gray)
                    .frame(width: 36, height: 36)
                    .background(themeColor.opacity(0.1))
                    .cornerRadius(18)
            }
            
            // 生成报价单
            Button(action: generateQuote) {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 16))
                    .foregroundColor(themeColor)
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
        .background(dataStore.storeData.storeNameBgColor.toColor())
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 2)
    }
    
    // MARK: - 生成报价单
    private func generateQuote() {
        let activeProducts = dataStore.storeData.products.filter { $0.isActive }
        guard !activeProducts.isEmpty else {
            quoteAlertMessage = "暂无商品可生成报价单"
            showQuoteAlert = true
            return
        }
        
        let quoteView = QuoteView(
            storeName: dataStore.storeData.storeName,
            products: activeProducts,
            categories: dataStore.storeData.categories,
            showPrice: dataStore.storeData.showPrice
        )
        
        let controller = UIHostingController(rootView: quoteView)
        guard let view = controller.view else {
            quoteAlertMessage = "生成图片失败"
            showQuoteAlert = true
            return
        }
        
        let targetWidth: CGFloat = 390
        let targetSize = CGSize(width: targetWidth, height: 0)
        view.frame = CGRect(origin: .zero, size: targetSize)
        view.backgroundColor = UIColor.white
        
        // 先布局一次获取实际高度
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        let fittingSize = view.systemLayoutSizeFitting(
            CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        
        guard fittingSize.width > 0, fittingSize.height > 0 else {
            quoteAlertMessage = "生成图片失败：尺寸异常"
            showQuoteAlert = true
            return
        }
        
        view.frame = CGRect(origin: .zero, size: fittingSize)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // 用 layer.render 代替 drawHierarchy，不需要在 window 层级中
        let renderer = UIGraphicsImageRenderer(size: fittingSize)
        let image = renderer.image { ctx in
            view.layer.render(in: ctx.cgContext)
        }
        
        let saver = PhotoLibrarySaver { [weak self] success in
            DispatchQueue.main.async {
                self?.quoteAlertMessage = success ? "报价单已保存到相册 📄" : "保存失败，请检查相册权限"
                self?.showQuoteAlert = true
            }
        }
        saver.save(image)
    }
}

// MARK: - 报价单视图

struct QuoteView: View {
    let storeName: String
    let products: [Product]
    let categories: [Category]
    let showPrice: Bool
    
    private var dateStr: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年MM月dd日"
        return f.string(from: Date())
    }
    
    /// 按分类分组的商品
    private var groupedProducts: [(category: Category, products: [Product])] {
        let realCats = categories.filter { $0.name != "全部" }
        var result: [(Category, [Product])] = []
        for cat in realCats {
            let catProducts = products.filter { $0.categoryId == cat.id }
            if !catProducts.isEmpty {
                result.append((cat, catProducts))
            }
        }
        // 没有分类的商品放在"其他"里
        let uncategorized = products.filter { p in !realCats.contains(where: { $0.id == p.categoryId }) }
        if !uncategorized.isEmpty {
            let otherCat = Category(name: "其他")
            result.append((otherCat, uncategorized))
        }
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部
            VStack(spacing: 6) {
                Text(storeName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.black)
                
                Text(dateStr)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Text("—— 报价单 ——")
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.7))
                    .padding(.top, 2)
            }
            .padding(.top, 32)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal, 20)
            
            // 商品列表
            ForEach(Array(groupedProducts.enumerated()), id: \.offset) { sectionIndex, group in
                VStack(alignment: .leading, spacing: 0) {
                    // 分类标题
                    Text(group.category.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    
                    // 该分类下的商品
                    ForEach(Array(group.products.enumerated()), id: \.element.id) { index, product in
                        HStack(alignment: .center) {
                            Text(product.name)
                                .font(.system(size: 15))
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            if showPrice {
                                HStack(spacing: 4) {
                                    if product.hasValidOriginalPrice {
                                        Text(product.originalPrice)
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                            .strikethrough()
                                    }
                                    
                                    Text(product.price)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.black)
                                    
                                    if product.hasValidOriginalPrice {
                                        Text(product.isPriceDown ? "降" : "涨")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(product.isPriceDown ? Color(red: 0.85, green: 0.64, blue: 0.13) : .red)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        
                        if index < group.products.count - 1 {
                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                }
                
                if sectionIndex < groupedProducts.count - 1 {
                    Divider()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                }
            }
            
            Divider()
                .padding(.horizontal, 20)
                .padding(.top, 8)
            
            // 底部
            Text("谢谢惠顾！欢迎下次光临")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.top, 16)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
}

// MARK: - 相册保存辅助

class PhotoLibrarySaver: NSObject {
    let callback: (Bool) -> Void
    
    init(callback: @escaping (Bool) -> Void) {
        self.callback = callback
    }
    
    func save(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(didFinishSaving), nil)
    }
    
    @objc func didFinishSaving(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        callback(error == nil)
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
                                .foregroundColor(.black)
                            
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
        // 打开 & 关闭均为 0.15s，干脆利落不拖沓
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
