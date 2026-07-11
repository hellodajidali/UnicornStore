import SwiftUI

// MARK: - 主界面

struct MainContentView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedCategoryId: UUID?
    @State private var showAdmin = false
    @State private var enlargedProduct: Product? = nil
    @State private var showQuoteAlert = false
    @State private var quoteAlertMessage = ""
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    
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
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ShareSheet(activityItems: [image])
                }
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
    
    // MARK: - 绘制单个商品行
    private func drawQuoteProduct(c: CGContext, product: Product, y: CGFloat, leftX: CGFloat, priceRightX: CGFloat, showP: Bool) {
        let nameAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.black
        ]
        let name = product.name as NSString
        var cx = leftX
        
        // 商品名
        name.draw(at: CGPoint(x: cx, y: y + 2), withAttributes: nameAttr)
        cx += name.size(withAttributes: nameAttr).width + 8
        
        if showP {
            // 原价
            if product.hasValidOriginalPrice {
                let origAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11),
                    .foregroundColor: UIColor.gray,
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue
                ]
                let origStr = product.originalPrice as NSString
                origStr.draw(at: CGPoint(x: cx, y: y + 4), withAttributes: origAttr)
                cx += origStr.size(withAttributes: origAttr).width + 6
            }
            
            // 现价
            let priceAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 15),
                .foregroundColor: UIColor.orange
            ]
            let priceStr = product.price as NSString
            priceStr.draw(at: CGPoint(x: cx, y: y + 2), withAttributes: priceAttr)
            cx += priceStr.size(withAttributes: priceAttr).width + 6
            
            // 涨/降
            if product.hasValidOriginalPrice {
                let isDown = product.isPriceDown
                let changeAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 10),
                    .foregroundColor: isDown ? UIColor.green : UIColor.red
                ]
                let changeStr = (isDown ? "降" : "涨") as NSString
                changeStr.draw(at: CGPoint(x: cx, y: y + 5), withAttributes: changeAttr)
                cx += changeStr.size(withAttributes: changeAttr).width + 6
            }
            
            // 活动标签
            if DataStore.shared.storeData.showPromotion && !product.promotion.isEmpty {
                // 分隔符 ·
                let sepAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.lightGray
                ]
                let sepStr = "·" as NSString
                sepStr.draw(at: CGPoint(x: cx, y: y + 5), withAttributes: sepAttr)
                cx += sepStr.size(withAttributes: sepAttr).width + 6
                
                let promoLabelAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 10),
                    .foregroundColor: UIColor.red
                ]
                let promoLabel = "活动：" as NSString
                promoLabel.draw(at: CGPoint(x: cx, y: y + 5), withAttributes: promoLabelAttr)
                cx += promoLabel.size(withAttributes: promoLabelAttr).width
                
                let promoContentAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.black
                ]
                (product.promotion as NSString).draw(at: CGPoint(x: cx, y: y + 5), withAttributes: promoContentAttr)
            }
        } else {
            name.draw(at: CGPoint(x: leftX, y: y + 2), withAttributes: nameAttr)
        }
    }
    
    // MARK: - 生成报价单
    private func generateQuote() {
        let activeProducts = dataStore.storeData.products.filter { $0.isActive }
        guard !activeProducts.isEmpty else {
            quoteAlertMessage = "暂无商品可生成报价单"
            showQuoteAlert = true
            return
        }
        
        // 按分类分组
        let realCats = dataStore.storeData.categories.filter { $0.name != "全部" }
        var groups: [(name: String, products: [Product])] = []
        for cat in realCats {
            let catProducts = activeProducts.filter { $0.categoryId == cat.id }
            if !catProducts.isEmpty {
                groups.append((cat.name, catProducts))
            }
        }
        let uncategorized = activeProducts.filter { p in !realCats.contains(where: { $0.id == p.categoryId }) }
        if !uncategorized.isEmpty {
            groups.append(("其他", uncategorized))
        }
        
        // 绘制参数
        let pageWidth: CGFloat = 390
        let margin: CGFloat = 24
        let contentWidth = pageWidth - margin * 2
        let leftX = margin
        let priceRightX = pageWidth - margin
        
        // 计算总高度
        var totalHeight: CGFloat = 60  // 顶部内边距
        totalHeight += 50  // 店名
        totalHeight += 30  // 日期
        totalHeight += 20  // 分隔线
        totalHeight += 8   // 间距
        for group in groups {
            totalHeight += 40  // 分类标题
            totalHeight += CGFloat(group.products.count) * 36  // 每行商品
            totalHeight += 12  // 分类间距
        }
        totalHeight += 50  // 底部"谢谢惠顾"
        totalHeight += 40  // 底部内边距
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: pageWidth, height: totalHeight))
        let showP = dataStore.storeData.showPrice
        let storeName = dataStore.storeData.storeName
        
        // 日期
        let df = DateFormatter()
        df.locale = Locale(identifier: "zh_CN")
        df.dateFormat = "yyyy年MM月dd日"
        let dateStr = df.string(from: Date())
        
        let image = renderer.image { ctx in
            let c = ctx.cgContext
            
            // 白色背景
            c.setFillColor(UIColor.white.cgColor)
            c.fill(CGRect(x: 0, y: 0, width: pageWidth, height: totalHeight))
            
            var y: CGFloat = 60
            
            // —— 店名 ——
            let titleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 26),
                .foregroundColor: UIColor.black
            ]
            let titleSize = (storeName as NSString).size(withAttributes: titleAttr)
            (storeName as NSString).draw(
                at: CGPoint(x: (pageWidth - titleSize.width) / 2, y: y),
                withAttributes: titleAttr
            )
            y += 40
            
            // —— 日期 ——
            let dateAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.gray
            ]
            let dateSize = (dateStr as NSString).size(withAttributes: dateAttr)
            (dateStr as NSString).draw(
                at: CGPoint(x: (pageWidth - dateSize.width) / 2, y: y),
                withAttributes: dateAttr
            )
            y += 24
            
            // —— 分隔线 ——
            c.setStrokeColor(UIColor.lightGray.withAlphaComponent(0.5).cgColor)
            c.setLineWidth(1)
            c.move(to: CGPoint(x: margin, y: y))
            c.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            c.strokePath()
            y += 20
            
            for groupIdx in 0..<groups.count {
                let group = groups[groupIdx]
                
                // —— 分类名 ——
                let catAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 17),
                    .foregroundColor: UIColor.black
                ]
                (group.name as NSString).draw(at: CGPoint(x: leftX, y: y), withAttributes: catAttr)
                y += 32
                
                // —— 商品行 ——
                let singleCol = dataStore.storeData.quoteSingleColumn
                if singleCol {
                    for product in group.products {
                        drawQuoteProduct(c: c, product: product, y: y, leftX: leftX, priceRightX: priceRightX, showP: showP)
                        y += 36
                    }
                } else {
                    let halfW = contentWidth / 2
                    let midX = leftX + halfW
                    for i in stride(from: 0, to: group.products.count, by: 2) {
                        let p1 = group.products[i]
                        let p1Right = midX - 6
                        drawQuoteProduct(c: c, product: p1, y: y, leftX: leftX, priceRightX: p1Right, showP: showP)
                        if i + 1 < group.products.count {
                            let p2 = group.products[i + 1]
                            drawQuoteProduct(c: c, product: p2, y: y, leftX: midX + 6, priceRightX: priceRightX, showP: showP)
                        }
                        y += 36
                    }
                }
                
                // 分类间分隔线
                if groupIdx < groups.count - 1 {
                    y += 4
                    c.setStrokeColor(UIColor.lightGray.withAlphaComponent(0.3).cgColor)
                    c.setLineWidth(0.5)
                    c.move(to: CGPoint(x: margin + 20, y: y))
                    c.addLine(to: CGPoint(x: pageWidth - margin, y: y))
                    c.strokePath()
                    y += 8
                }
            }
            
            // —— 底部 ——
            y += 8
            c.setStrokeColor(UIColor.lightGray.withAlphaComponent(0.5).cgColor)
            c.setLineWidth(1)
            c.move(to: CGPoint(x: margin, y: y))
            c.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            c.strokePath()
            y += 16
            
            let footer = dataStore.storeData.quoteFooter
            let footerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.gray
            ]
            let footerSize = (footer as NSString).size(withAttributes: footerAttr)
            (footer as NSString).draw(
                at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: y),
                withAttributes: footerAttr
            )
        }
        
        shareImage = image
        showShareSheet = true
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
