import SwiftUI
import UniformTypeIdentifiers

// MARK: - 管理后台面板

struct AdminPanelView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @State private var showPriceToggle = true
    @State private var showExportAlert = false
    @State private var exportMessage = ""
    @State private var showShareSheet = false
    @State private var shareFileURL: URL? = nil
    @State private var showFileImporter = false
    @State private var showImportAlert = false
    @State private var importMessage = ""
    
    private var themeColor: Color {
        dataStore.storeData.themeColor.toColor()
    }
    
    var body: some View {
        NavigationView {
            List {
                // 商店名称设置
                StoreNameEditView()
                
                // 公告栏设置
                AnnouncementEditView()
                
                // 分类管理
                CategoryEditView()
                
                // 商品管理
                Section(header: Text("商品管理").font(.headline)) {
                    NavigationLink(destination: ProductListView()) {
                        HStack {
                            Image(systemName: "shippingbox.fill")
                                .foregroundColor(themeColor)
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
                    
                    Toggle(isOn: Binding(
                        get: { dataStore.storeData.showPromotion },
                        set: { dataStore.storeData.showPromotion = $0 }
                    )) {
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(.red)
                            VStack(alignment: .leading) {
                                Text("显示活动标签")
                                    .font(.system(size: 15, weight: .medium))
                                Text("关闭后商品活动信息不显示")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    // 整体主题色设置
                    ThemeColorEditView()
                }
                
                // 报价单设置
                Section(header: Text("报价单管理").font(.headline)) {
                    Toggle(isOn: Binding(
                        get: { dataStore.storeData.quoteSingleColumn },
                        set: { dataStore.storeData.quoteSingleColumn = $0 }
                    )) {
                        HStack {
                            Image(systemName: "text.viewfinder")
                                .foregroundColor(themeColor)
                            VStack(alignment: .leading) {
                                Text("单排显示")
                                    .font(.system(size: 15, weight: .medium))
                                Text("关闭后商品双排显示")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("底部文字：")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextField("输入底部文字", text: Binding(
                            get: { dataStore.storeData.quoteFooter },
                            set: { dataStore.storeData.quoteFooter = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 4)
                }
                
                // 数据管理
                Section(header: Text("数据管理").font(.headline)) {
                    Button(action: exportBackup) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                                .foregroundColor(.blue)
                            Text("导出数据备份")
                                .font(.system(size: 15))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button(action: {
                        showFileImporter = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down.fill")
                                .foregroundColor(.green)
                            Text("导入数据备份")
                                .font(.system(size: 15))
                                .foregroundColor(.green)
                        }
                    }
                    
                    Button(action: {
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
                .foregroundColor(themeColor)
            )
            .alert(isPresented: $showExportAlert) {
                Alert(
                    title: Text("操作完成"),
                    message: Text(exportMessage),
                    dismissButton: .default(Text("确定"))
                )
            }
            .alert(isPresented: $showImportAlert) {
                Alert(
                    title: Text("导入结果"),
                    message: Text(importMessage),
                    dismissButton: .default(Text("确定"))
                )
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = shareFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .sheet(isPresented: $showFileImporter) {
                DocumentPickerView { url in
                    importFile(url: url)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func exportBackup() {
        if let url = dataStore.getBackupFileURL() {
            shareFileURL = url
            showShareSheet = true
        } else {
            exportMessage = "导出失败，请重试"
            showExportAlert = true
        }
    }
    
    private func importFile(url: URL) {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            let data = try Data(contentsOf: url)
            if dataStore.importData(data) {
                importMessage = "数据导入成功！"
            } else {
                importMessage = "导入失败：数据格式不正确"
            }
        } catch {
            importMessage = "导入失败：\(error.localizedDescription)"
        }
        showImportAlert = true
    }
}

// MARK: - 商店名称编辑

struct StoreNameEditView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var storeName: String = ""
    @State private var fontSize: CGFloat = 24
    @State private var textColor: String = "#9966CC"
    @State private var nameBgColor: String = "#FFFFFF"
    
    private let presetColors = ["#9966CC", "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#FF8C00", "#20B2AA", "#FF69B4", "#333333", "#000000"]
    
    var body: some View {
        Section(header: Text("商店名称").font(.headline)) {
            VStack(alignment: .leading, spacing: 10) {
                Text("名称文字：")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextField("输入商店名称", text: $storeName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onAppear {
                        storeName = dataStore.storeData.storeName
                        fontSize = dataStore.storeData.storeNameFontSize
                        textColor = dataStore.storeData.storeNameColor
                        nameBgColor = dataStore.storeData.storeNameBgColor
                    }
                
                // 字体大小
                VStack(alignment: .leading, spacing: 4) {
                    Text("字体大小：\(Int(fontSize))")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Slider(value: $fontSize, in: 16...40, step: 1)
                }
                
                // 字体颜色
                VStack(alignment: .leading, spacing: 4) {
                    Text("字体颜色：")
                        .font(.caption)
                        .foregroundColor(.gray)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                        ForEach(presetColors, id: \.self) { color in
                            Circle()
                                .fill(color.toColor())
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(textColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    textColor = color
                                }
                        }
                    }
                }
                
                // 背景颜色切换（和字体颜色相同色板 + 白色+灰色）
                VStack(alignment: .leading, spacing: 6) {
                    Text("顶栏背景颜色：")
                        .font(.caption)
                        .foregroundColor(.gray)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                        ForEach(presetColors + ["#FFFFFF", "#F0F0F0"], id: \.self) { color in
                            Circle()
                                .fill(color.toColor())
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(nameBgColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(color == "#FFFFFF" ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                                .onTapGesture {
                                    nameBgColor = color
                                }
                        }
                    }
                }
                
                // 预览
                Text(storeName.isEmpty ? "预览" : storeName)
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundColor(textColor.toColor())
                    .padding(.vertical, 4)
            }
            .padding(.vertical, 4)
            
            Button("保存名称设置") {
                dataStore.storeData.storeName = storeName
                dataStore.storeData.storeNameFontSize = fontSize
                dataStore.storeData.storeNameColor = textColor
                dataStore.storeData.storeNameBgColor = nameBgColor
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

// MARK: - 主题色编辑

struct ThemeColorEditView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var themeColor: String = "#9966CC"
    
    private let presetColors = ["#9966CC", "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#FF8C00", "#20B2AA", "#FF69B4", "#E74C3C", "#2ECC71", "#3498DB", "#9B59B6", "#1ABC9C", "#F39C12", "#FFFFFF", "#808080", "#E0E0E0"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("整体主题颜色：")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                ForEach(presetColors, id: \.self) { color in
                    Circle()
                        .fill(color.toColor())
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(themeColor == color ? Color.primary : Color.clear, lineWidth: 3)
                        )
                        .shadow(color: color.toColor().opacity(0.3), radius: themeColor == color ? 6 : 0)
                        .onTapGesture {
                            themeColor = color
                            dataStore.storeData.themeColor = color
                        }
                }
            }
            .padding(.vertical, 4)
            
            Text("当前主题色预览")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeColor == "#FFFFFF" || themeColor == "#FFEAA7" ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(themeColor.toColor())
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeColor == "#FFFFFF" ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        }
        .padding(.vertical, 4)
        .onAppear {
            themeColor = dataStore.storeData.themeColor
        }
    }
}

// MARK: - 分享面板（UIActivityViewController Bridge）

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - 商品列表视图

struct ProductListView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var editingProduct: Product?
    @State private var deleteProduct: Product?
    @State private var showDeleteAlert = false
    @State private var filterCategoryId: UUID? = nil
    @State private var editMode: EditMode = .inactive
    
    private var filteredProducts: [Product] {
        if let catId = filterCategoryId {
            return dataStore.storeData.products.filter { $0.categoryId == catId }
        }
        return dataStore.storeData.products
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 分类筛选栏
            if !dataStore.storeData.categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(dataStore.storeData.categories) { category in
                            let isAll = category.name == "全部"
                            let isSelected = isAll ? (filterCategoryId == nil) : (filterCategoryId == category.id)
                            Button(action: {
                                if isAll {
                                    filterCategoryId = nil
                                } else {
                                    filterCategoryId = category.id
                                }
                            }) {
                                Text(category.name)
                                    .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                                    .foregroundColor(isSelected ? .white : dataStore.storeData.themeColor.toColor())
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(
                                        isSelected ?
                                            dataStore.storeData.themeColor.toColor() :
                                            dataStore.storeData.themeColor.toColor().opacity(0.1)
                                    )
                                    .cornerRadius(14)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color(.systemGroupedBackground))
            }
            
            List {
                if filteredProducts.isEmpty {
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
                    ForEach(filteredProducts) { product in
                        SwipeToDeleteRow {
                            ProductRowView(product: product) {
                                editingProduct = product
                            }
                        } onDelete: {
                            dataStore.deleteProduct(product)
                        }
                    }
                    .onMove(perform: moveProduct)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .environment(\.editMode, $editMode)
        }
        .navigationTitle("商品列表 (\(filteredProducts.count))")
        .navigationBarItems(
            trailing: HStack {
                if editMode == .active {
                    Button("完成") {
                        editMode = .inactive
                    }
                } else {
                    Button("排序") {
                        editMode = .active
                    }
                }
            }
        )
        .sheet(item: $editingProduct) { product in
            EditProductView(product: product)
                .environmentObject(dataStore)
        }
    }
    
    private func moveProduct(from source: IndexSet, to destination: Int) {
        // 如果按分类筛选，需要映射到原始数组的index
        if let catId = filterCategoryId {
            // 从筛选结果映射到原始products数组
            let movingItems = source.map { filteredProducts[$0] }
            var allProducts = dataStore.storeData.products
            
            // 先移除要移动的商品
            for item in movingItems {
                allProducts.removeAll { $0.id == item.id }
            }
            
            // 计算目标位置在原始数组中的index
            let destProduct: Product?
            if destination < filteredProducts.count {
                destProduct = filteredProducts[destination]
            } else {
                destProduct = nil
            }
            
            if let destProduct = destProduct, let insertIndex = allProducts.firstIndex(where: { $0.id == destProduct.id }) {
                for item in movingItems.reversed() {
                    allProducts.insert(item, at: insertIndex)
                }
            } else {
                allProducts.append(contentsOf: movingItems)
            }
            
            dataStore.storeData.products = allProducts
        } else {
            dataStore.moveProduct(from: source, to: destination)
        }
    }
}

// MARK: - 商品行视图

struct ProductRowView: View {
    let product: Product
    let onTap: () -> Void
    
    private var themeColor: Color {
        DataStore.shared.storeData.themeColor.toColor()
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // 缩略图 + 商品信息（可点击跳转编辑）
            HStack(spacing: 12) {
                // 缩略图
                if let image = product.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .opacity(product.isActive ? 1 : 0.4)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 60, height: 60)
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .opacity(product.isActive ? 1 : 0.4)
                    }
                }
                
                // 商品信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(product.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(product.isActive ? .primary : .gray)
                        
                        if !product.isActive {
                            Text("已隐藏")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray)
                                .cornerRadius(4)
                        }
                    }
                    
                    if DataStore.shared.storeData.showPrice {
                        Text(product.price)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(product.isActive ? .orange : .gray)
                    }
                    
                    if !product.description.isEmpty {
                        Text(product.description)
                            .font(.system(size: 12))
                            .foregroundColor(product.isActive ? .gray : .gray.opacity(0.5))
                            .lineLimit(1)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            
            Spacer()
            
            // 编辑按钮
            Button(action: onTap) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 15))
                    .foregroundColor(themeColor)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            // 上架/下架开关（可独立点击，不会触发编辑）
            Toggle(isOn: Binding(
                get: { product.isActive },
                set: { newValue in
                    if let idx = DataStore.shared.storeData.products.firstIndex(where: { $0.id == product.id }) {
                        var updated = DataStore.shared.storeData
                        updated.products[idx].isActive = newValue
                        DataStore.shared.storeData = updated
                    }
                }
            )) { }
            .labelsHidden()
            .toggleStyle(SwitchToggleStyle(tint: themeColor))
            .scaleEffect(0.8)
            .fixedSize()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 滑动删除容器（兼容iOS 14+）
//
struct SwipeToDeleteRow<Content: View>: View {
    let content: Content
    let onDelete: () -> Void
    
    @State private var offsetX: CGFloat = 0
    @State private var showDelete = false
    @Environment(\.editMode) var editMode
    private let deleteButtonWidth: CGFloat = 80
    
    init(@ViewBuilder content: () -> Content, onDelete: @escaping () -> Void) {
        self.content = content()
        self.onDelete = onDelete
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // 删除按钮（在内容后面）
            HStack {
                Spacer()
                Button(action: {
                    onDelete()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18))
                        Text("删除")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                    .frame(width: deleteButtonWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
            // 主要内容
            if editMode?.wrappedValue == .active {
                // 排序模式下：禁用滑动删除手势，避免与 .onMove 拖拽冲突
                content
                    .background(Color(.systemBackground))
                    .offset(x: offsetX)
            } else {
                content
                    .background(Color(.systemBackground))
                    .offset(x: offsetX)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.width < 0 {
                                    offsetX = max(-deleteButtonWidth, value.translation.width)
                                }
                            }
                            .onEnded { value in
                                withAnimation(.easeOut(duration: 0.2)) {
                                    if value.translation.width < -deleteButtonWidth * 0.4 {
                                        offsetX = -deleteButtonWidth
                                        showDelete = true
                                    } else {
                                        offsetX = 0
                                        showDelete = false
                                    }
                                }
                            }
                    )
            }
        }
        .clipped()
    }
}

// MARK: - 文件选择器（UIViewControllerRepresentable + Coordinator，稳定可靠）
struct DocumentPickerView: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // 更新时重新设置 delegate，确保状态同步
        uiViewController.delegate = context.coordinator
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        
        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
