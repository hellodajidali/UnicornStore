import SwiftUI

// MARK: - 商品网格视图

struct ProductGridView: View {
    let products: [Product]
    let onEnlarge: ((Product) -> Void)?
    @EnvironmentObject var dataStore: DataStore
    
    init(products: [Product], onEnlarge: ((Product) -> Void)? = nil) {
        self.products = products
        self.onEnlarge = onEnlarge
    }
    
    private var columns: Int {
        max(2, min(dataStore.storeData.gridColumns, 5))
    }
    
    private var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: columns)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if products.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cart.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("暂无商品")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    Text("请到管理后台添加商品")
                        .font(.system(size: 13))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else if dataStore.storeData.showTextOnly {
                // 纯文字显示模式
                textOnlyListView
            } else {
                LazyVGrid(columns: gridItems, spacing: 12) {
                    ForEach(products) { product in
                        ProductCard(product: product, onEnlarge: onEnlarge)
                    }
                }
            }
        }
    }
    
    // MARK: - 纯文字显示列表
    private var textOnlyListView: some View {
        VStack(spacing: 0) {
            ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                TextOnlyProductRow(product: product, onEnlarge: onEnlarge)
                
                if index < products.count - 1 {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

// MARK: - 标签视图组件

/// 文字标（带框）
struct TextBadgeView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(color, lineWidth: 1)
            )
    }
}

/// 热度标（无框）
struct HotBadgeView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - 纯文字商品行

struct TextOnlyProductRow: View {
    let product: Product
    let onEnlarge: ((Product) -> Void)?
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        HStack(spacing: 8) {
            // 文字标（带框，在商品名前）
            if !product.textBadge.isEmpty {
                TextBadgeView(text: product.textBadge, color: product.textBadgeColor.toColor())
                    .fixedSize()
            }
            
            // 商品名（双击放大查看）
            Text(product.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
            
            // 热度标（在商品名和原价中间，不受 showPrice 控制）
            if !product.hotBadge.isEmpty {
                HotBadgeView(text: product.hotBadge, color: product.hotBadgeColor.toColor())
                    .padding(.leading, 2)
            }
            
            // 原价/现价/涨降（由 showPrice 控制）
            if dataStore.storeData.showPrice {
                // 原价（如有，灰色删除线）
                if product.hasValidOriginalPrice {
                    Text(product.originalPrice)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .strikethrough()
                }
                
                // 现价
                Text(product.price)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.orange)
                
                // 涨/降文字（金色=降，红色=涨）
                if product.hasValidOriginalPrice {
                    Text(product.isPriceDown ? "降" : "涨")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(product.isPriceDown ? .green : .red)
                }
            }
            
            // 活动标签（不受 showPrice 控制）
            if dataStore.storeData.showPromotion && !product.promotion.isEmpty {
                Text("·")
                    .foregroundColor(.gray)
                    .font(.system(size: 14, weight: .bold))
                (Text("活动：")
                    .foregroundColor(.red)
                + Text(product.promotion)
                    .foregroundColor(.primary))
                    .font(.system(size: 13, weight: .bold))
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .gesture(
            TapGesture(count: 2)
                .onEnded {
                    onEnlarge?(product)
                }
                .simultaneously(with: TapGesture(count: 1)
                    .onEnded {
                        // 单击不做特殊动作，但保留手势槽位避免和双击冲突
                    })
        )
    }
}

// MARK: - 商品卡片

struct ProductCard: View {
    let product: Product
    let onEnlarge: ((Product) -> Void)?
    @EnvironmentObject var dataStore: DataStore
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            // 商品图片
            ZStack {
                if let image = product.image {
                    DraggableProductImage(
                        image: image,
                        frameWidth: cardWidth,
                        frameHeight: cardWidth * 0.9,
                        offsetX: .constant(product.imageOffsetX),
                        offsetY: .constant(product.imageOffsetY),
                        draggable: false
                    )
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        dataStore.storeData.themeColor.toColor().opacity(0.15),
                                        dataStore.storeData.themeColor.toColor().opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: cardWidth, height: cardWidth * 0.9)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(dataStore.storeData.themeColor.toColor().opacity(0.4))
                            Text("添加图片")
                                .font(.system(size: 11))
                                .foregroundColor(dataStore.storeData.themeColor.toColor().opacity(0.4))
                        }
                    }
                }
            }
            .cornerRadius(8)
            .scaleEffect(scale)
            .gesture(
                TapGesture(count: 2)
                    .onEnded {
                        onEnlarge?(product)
                    }
                    .simultaneously(with: TapGesture(count: 1)
                        .onEnded {
                            withAnimation(.spring(response: 0.2)) {
                                scale = 0.95
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.2)) {
                                    scale = 1.0
                                }
                            }
                        })
            )
            
            // 商品名称（前面加文字标）
            HStack(spacing: 4) {
                if !product.textBadge.isEmpty {
                    TextBadgeView(text: product.textBadge, color: product.textBadgeColor.toColor())
                        .fixedSize()
                }
                Text(product.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 6)
            .padding(.top, 6)
            
            // 价格区域（热度标不受 showPrice 控制，原价/现价/涨降由开关控制）
            if !product.hotBadge.isEmpty || dataStore.storeData.showPrice ||
               (dataStore.storeData.showPromotion && !product.promotion.isEmpty) {
                VStack(spacing: 4) {
                    // 第一行：热度标 + 原价/现价/涨降
                    if !product.hotBadge.isEmpty || dataStore.storeData.showPrice {
                        HStack(spacing: 4) {
                            // 热度标（始终显示）
                            if !product.hotBadge.isEmpty {
                                HotBadgeView(text: product.hotBadge, color: product.hotBadgeColor.toColor())
                            }
                            
                            // 原价/现价/涨降（受 showPrice 控制）
                            if dataStore.storeData.showPrice {
                                // 原价（如有，灰色删除线）
                                if product.hasValidOriginalPrice {
                                    Text(product.originalPrice)
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                        .strikethrough()
                                }
                                
                                // 现价
                                Text(product.price)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.orange)
                                
                                // 涨/降文字（绿色=降，红色=涨）
                                if product.hasValidOriginalPrice {
                                    Text(product.isPriceDown ? "降" : "涨")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(product.isPriceDown ? .green : .red)
                                }
                            }
                        }
                    }
                    
                    // 第二行：活动标签（独立一行，无 · 分隔符，不受 showPrice 控制）
                    if dataStore.storeData.showPromotion && !product.promotion.isEmpty {
                        HStack(spacing: 2) {
                            Text("活动：")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red)
                            Text(product.promotion)
                                .font(.system(size: 10))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.bottom, 8)
            } else {
                // 即使没有内容也保持底部间距一致
                Spacer().frame(height: 8)
            }
        }
        .frame(width: cardWidth)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var cardWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 24
        let spacing: CGFloat = 10 * CGFloat(columns - 1)
        return (screenWidth - spacing) / CGFloat(columns)
    }
    
    private var columns: Int {
        max(2, min(DataStore.shared.storeData.gridColumns, 5))
    }
}

// MARK: - 网格列数设置视图（管理后台用）

struct GridLayoutEditView: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("选择每行显示的商品数量（2~5排）：")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                ForEach(2...5, id: \.self) { num in
                    Button(action: {
                        dataStore.storeData.gridColumns = num
                    }) {
                        Text("\(num)排")
                            .font(.system(size: 16, weight: dataStore.storeData.gridColumns == num ? .bold : .regular))
                            .foregroundColor(dataStore.storeData.gridColumns == num ? .white : dataStore.storeData.themeColor.toColor().opacity(0.7))
                            .frame(width: 60, height: 40)
                            .background(
                                dataStore.storeData.gridColumns == num ?
                                    dataStore.storeData.themeColor.toColor() :
                                    dataStore.storeData.themeColor.toColor().opacity(0.1)
                            )
                            .cornerRadius(10)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
        .padding(.vertical, 4)
    }
}
