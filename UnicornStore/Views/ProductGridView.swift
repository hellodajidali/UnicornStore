import SwiftUI

// MARK: - 商品网格视图

struct ProductGridView: View {
    let products: [Product]
    @Binding var enlargedProduct: Product?
    @EnvironmentObject var dataStore: DataStore
    
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
            } else {
                LazyVGrid(columns: gridItems, spacing: 12) {
                    ForEach(products) { product in
                        ProductCard(
                            product: product,
                            onDoubleTap: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    enlargedProduct = product
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - 商品卡片

struct ProductCard: View {
    let product: Product
    let onDoubleTap: () -> Void
    @EnvironmentObject var dataStore: DataStore
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            // 商品图片
            ZStack {
                if let image = product.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: cardWidth, height: cardWidth * 0.9)
                        .clipped()
                } else {
                    // 默认占位图
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.95, green: 0.9, blue: 0.98),
                                        Color(red: 0.9, green: 0.85, blue: 0.95)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: cardWidth, height: cardWidth * 0.9)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.6).opacity(0.4))
                            Text("添加图片")
                                .font(.system(size: 11))
                                .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.6).opacity(0.4))
                        }
                    }
                }
            }
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
            .scaleEffect(scale)
            .onTapGesture(count: 2) {
                // 双击放大
                onDoubleTap()
            }
            .onTapGesture(count: 1) {
                // 单击效果（轻反馈）
                withAnimation(.spring(response: 0.2)) {
                    scale = 0.95
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.2)) {
                        scale = 1.0
                    }
                }
            }
            
            // 商品名称
            Text(product.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 36)
            
            // 价格（可隐藏）
            if dataStore.storeData.showPrice {
                Text(product.price)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.orange)
            }
        }
        .padding(.bottom, 4)
    }
    
    private var cardWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 24 // 12 padding on each side
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
    @State private var selectedColumns: Int = 3
    
    var body: some View {
        Section(header: Text("商品布局").font(.headline)) {
            VStack(alignment: .leading, spacing: 10) {
                Text("选择每行显示的商品数量（2~5排）：")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 12) {
                    ForEach(2...5, id: \.self) { num in
                        Button(action: {
                            selectedColumns = num
                            dataStore.storeData.gridColumns = num
                        }) {
                            Text("\(num)排")
                                .font(.system(size: 16, weight: selectedColumns == num ? .bold : .regular))
                                .foregroundColor(selectedColumns == num ? .white : Color(red: 0.4, green: 0.15, blue: 0.5))
                                .frame(width: 60, height: 40)
                                .background(
                                    selectedColumns == num ?
                                        Color(red: 0.6, green: 0.2, blue: 0.6) :
                                        Color(red: 0.95, green: 0.9, blue: 0.98)
                                )
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            .onAppear {
                selectedColumns = dataStore.storeData.gridColumns
            }
        }
    }
}
