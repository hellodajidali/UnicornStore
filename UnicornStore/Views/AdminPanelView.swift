import SwiftUI

// MARK: - 管理后台面板

struct AdminPanelView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @State private var showPriceToggle = true
    @State private var showExportAlert = false
    @State private var exportMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                // 顶部横幅设置
                TopBannerEditView()
                
                // 公告栏设置
                AnnouncementEditView()
                
                // 分类管理
                CategoryEditView()
                
                // 商品管理
                Section(header: Text("商品管理").font(.headline)) {
                    NavigationLink(destination: ProductListView()) {
                        HStack {
                            Image(systemName: "shippingbox.fill")
                                .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.6))
                            VStack(alignment: .leading) {
                                Text("管理商品列表")
                                    .font(.system(size: 15, weight: .medium))
                                Text("添加、编辑、删除商品")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    NavigationLink(destination: AddProductView()) {
                        HStack {
                            Image(systemName: "plus.app.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("添加新商品")
                                    .font(.system(size: 15, weight: .medium))
                                Text("添加图片、名称、价格、分类")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // 布局与显示设置
                Section(header: Text("布局与显示").font(.headline)) {
                    GridLayoutEditView()
                    
                    // 显示/隐藏价格
                    Toggle(isOn: $showPriceToggle) {
                        HStack {
                            Image(systemName: "yensign.circle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text("显示价格")
                                    .font(.system(size: 15, weight: .medium))
                                Text("关闭后商品价格将隐藏")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .onChange(of: showPriceToggle) { newValue in
                        dataStore.storeData.showPrice = newValue
                    }
                    .onAppear {
                        showPriceToggle = dataStore.storeData.showPrice
                    }
                }
                
                // 数据管理
                Section(header: Text("数据管理").font(.headline)) {
                    Button(action: {
                        if let data = dataStore.exportData(),
                           let jsonString = String(data: data, encoding: .utf8) {
                            exportMessage = "数据已导出！可在控制台查看。\n数据大小: \(data.count) 字节"
                            showExportAlert = true
                            print("导出数据:\n\(jsonString)")
                        }
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                                .foregroundColor(.blue)
                            Text("导出数据备份")
                                .font(.system(size: 15))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button(action: {
                        // 重置为默认数据
                        dataStore.storeData = StoreData.defaultData()
                        exportMessage = "已重置为默认数据"
                        showExportAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .foregroundColor(.red)
                            Text("重置为默认数据")
                                .font(.system(size: 15))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("管理后台")
            .navigationBarItems(
                trailing: Button("完成") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.6))
            )
            .alert("操作完成", isPresented: $showExportAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(exportMessage)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - 商品列表视图

struct ProductListView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var editingProduct: Product?
    @State private var showEditSheet = false
    @State private var deleteProduct: Product?
    @State private var showDeleteAlert = false
    
    var body: some View {
        List {
            if dataStore.storeData.products.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("暂无商品")
                            .foregroundColor(.gray)
                            .padding(.vertical, 20)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                ForEach(dataStore.storeData.products) { product in
                    ProductRowView(product: product)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingProduct = product
                            showEditSheet = true
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteProduct = product
                                showDeleteAlert = true
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("商品列表 (\(dataStore.storeData.products.count))")
        .sheet(isPresented: $showEditSheet) {
            if let product = editingProduct {
                EditProductView(product: product)
                    .environmentObject(dataStore)
            }
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let product = deleteProduct {
                    dataStore.deleteProduct(product)
                }
            }
        } message: {
            Text("确定要删除这个商品吗？此操作不可恢复。")
        }
    }
}

// MARK: - 商品行视图

struct ProductRowView: View {
    let product: Product
    
    var body: some View {
        HStack(spacing: 12) {
            // 缩略图
            if let image = product.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
            }
            
            // 商品信息
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 15, weight: .medium))
                
                if DataStore.shared.storeData.showPrice {
                    Text(product.price)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.orange)
                }
                
                if !product.description.isEmpty {
                    Text(product.description)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}
