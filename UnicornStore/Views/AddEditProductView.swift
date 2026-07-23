import SwiftUI

// MARK: - 添加商品视图

struct AddProductView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = ""
    @State private var price: String = "¥"
    @State private var originalPrice: String = "¥"
    @State private var promotion: String = ""
    @State private var description: String = ""
    @State private var selectedCategoryId: UUID?
    @State private var productImage: UIImage?
    @State private var showImagePicker = false
    @State private var imageOffsetX: CGFloat = 0
    @State private var imageOffsetY: CGFloat = 0
    
    // 文字标
    @State private var textBadge: String = ""
    @State private var textBadgeColor: String = "#FF4500"
    
    // 热度标
    @State private var hotBadge: String = ""
    @State private var hotBadgeColor: String = "#FF4500"
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        price.trimmingCharacters(in: .whitespaces).count > 1
    }
    
    private var cardWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 24
        let columns = max(2, min(dataStore.storeData.gridColumns, 5))
        let spacing: CGFloat = 10 * CGFloat(columns - 1)
        return (screenWidth - spacing) / CGFloat(columns)
    }
    
    var body: some View {
        Form {
            Section(header: Text("商品信息").font(.headline)) {
                // 图片选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("商品图片：")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if let image = productImage {
                        DraggableProductImage(
                            image: image,
                            frameWidth: cardWidth,
                            frameHeight: cardWidth * 0.9,
                            offsetX: $imageOffsetX,
                            offsetY: $imageOffsetY,
                            draggable: true
                        )
                        Text("拖动图片可调整显示位置")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button("点击更换图片") {
                            showImagePicker = true
                        }
                        .font(.caption)
                        .foregroundColor(dataStore.storeData.themeColor.toColor())
                    } else {
                        Button(action: {
                            showImagePicker = true
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                    .frame(width: cardWidth, height: cardWidth * 0.9)
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 30))
                                        .foregroundColor(dataStore.storeData.themeColor.toColor())
                                    Text("点击添加图片")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                
                HStack {
                    Text("名称")
                        .foregroundColor(.gray)
                    TextField("输入商品名称", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack {
                    Text("价格")
                        .foregroundColor(.gray)
                    TextField("如: ¥99.00", text: $price)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
                
                HStack {
                    Text("原价")
                        .foregroundColor(.gray)
                    TextField("如: ¥129.00（留空不显示）", text: $originalPrice)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                }
                
                HStack {
                    Text("活动")
                        .foregroundColor(.gray)
                    TextField("如: 限时特价（留空不显示）", text: $promotion)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            Section(header: Text("分类").font(.headline)) {
                if dataStore.storeData.categories.isEmpty {
                    Text("暂无分类，请先添加分类")
                        .foregroundColor(.gray)
                } else {
                    Picker("选择分类", selection: $selectedCategoryId) {
                        ForEach(dataStore.storeData.categories) { category in
                            Text(category.name).tag(category.id as UUID?)
                                .font(.system(size: 15))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onAppear {
                        // 默认选中第一个非"全部"的分类
                        if selectedCategoryId == nil {
                            let firstReal = dataStore.storeData.categories.first(where: { $0.name != "全部" })
                            selectedCategoryId = firstReal?.id ?? dataStore.storeData.categories.first?.id
                        }
                    }
                    
                    // 显示当前选中的分类
                    HStack {
                        Text("当前选中：")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        if let catId = selectedCategoryId,
                           let cat = dataStore.storeData.categories.first(where: { $0.id == catId }) {
                            Text(cat.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(dataStore.storeData.themeColor.toColor())
                        } else {
                            Text("未选择")
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            
            // 文字标设置
            Section(header: Text("文字标").font(.headline)) {
                if dataStore.storeData.textBadgeOptions.isEmpty {
                    Text("暂无文字标选项，请先在管理后台添加")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Picker("选择文字标", selection: $textBadge) {
                        Text("无").tag("")
                        ForEach(dataStore.storeData.textBadgeOptions) { option in
                            Text(option.name).tag(option.name)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: textBadge) { newValue in
                        // 选中选项时自动设置颜色
                        if let option = dataStore.storeData.textBadgeOptions.first(where: { $0.name == newValue }) {
                            textBadgeColor = option.color
                        }
                    }
                }
                
                if !textBadge.isEmpty {
                    HStack {
                        Text("颜色：")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        ColorPicker("", selection: Binding(
                            get: { textBadgeColor.toColor() },
                            set: { textBadgeColor = $0.toHex() }
                        ))
                        .labelsHidden()
                    }
                }
            }
            
            // 热度标设置
            Section(header: Text("热度标").font(.headline)) {
                if dataStore.storeData.hotBadgeOptions.isEmpty {
                    Text("暂无热度标选项，请先在管理后台添加")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Picker("选择热度标", selection: $hotBadge) {
                        Text("无").tag("")
                        ForEach(dataStore.storeData.hotBadgeOptions) { option in
                            Text(option.name).tag(option.name)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: hotBadge) { newValue in
                        // 选中选项时自动设置颜色
                        if let option = dataStore.storeData.hotBadgeOptions.first(where: { $0.name == newValue }) {
                            hotBadgeColor = option.color
                        }
                    }
                }
                
                if !hotBadge.isEmpty {
                    HStack {
                        Text("颜色：")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        ColorPicker("", selection: Binding(
                            get: { hotBadgeColor.toColor() },
                            set: { hotBadgeColor = $0.toHex() }
                        ))
                        .labelsHidden()
                    }
                }
            }
            
            Section {
                Button(action: saveProduct) {
                    Text("添加商品")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(isFormValid ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isFormValid ? dataStore.storeData.themeColor.toColor() : Color.gray.opacity(0.3))
                        .cornerRadius(10)
                }
                .disabled(!isFormValid)
            }
        }
        .navigationTitle("添加新商品")
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(selectedImage: $productImage, onImagePicked: { image in
                self.productImage = image
            })
        }
    }
    
    private func saveProduct() {
        guard isFormValid else { return }
        
        let imageData = productImage?.jpegData(compressionQuality: 0.8)
        let catId = selectedCategoryId ?? dataStore.storeData.categories.first?.id
        
        let product = Product(
            name: name.trimmingCharacters(in: .whitespaces),
            price: price.trimmingCharacters(in: .whitespaces),
            originalPrice: originalPrice.trimmingCharacters(in: .whitespaces),
            categoryId: catId,
            imageData: imageData,
            description: description.trimmingCharacters(in: .whitespaces),
            imageOffsetX: imageOffsetX,
            imageOffsetY: imageOffsetY,
            promotion: promotion.trimmingCharacters(in: .whitespaces),
            textBadge: textBadge,
            textBadgeColor: textBadgeColor,
            hotBadge: hotBadge,
            hotBadgeColor: hotBadgeColor
        )
        
        dataStore.addProduct(product)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - 编辑商品视图

struct EditProductView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    
    let product: Product
    
    @State private var name: String = ""
    @State private var price: String = "¥"
    @State private var originalPrice: String = ""
    @State private var promotion: String = ""
    @State private var description: String = ""
    @State private var selectedCategoryId: UUID?
    @State private var productImage: UIImage?
    @State private var showImagePicker = false
    @State private var hasChanges = false
    @State private var isLoaded = false
    @State private var imageOffsetX: CGFloat = 0
    @State private var imageOffsetY: CGFloat = 0
    
    // 文字标
    @State private var textBadge: String = ""
    @State private var textBadgeColor: String = "#FF4500"
    
    // 热度标
    @State private var hotBadge: String = ""
    @State private var hotBadgeColor: String = "#FF4500"
    
    private var cardWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width - 24
        let columns = max(2, min(dataStore.storeData.gridColumns, 5))
        let spacing: CGFloat = 10 * CGFloat(columns - 1)
        return (screenWidth - spacing) / CGFloat(columns)
    }
    
    var body: some View {
        Form {
            Section(header: Text("商品信息").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("商品图片（点击更换）：")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if let image = productImage {
                        DraggableProductImage(
                            image: image,
                            frameWidth: cardWidth,
                            frameHeight: cardWidth * 0.9,
                            offsetX: $imageOffsetX,
                            offsetY: $imageOffsetY,
                            draggable: true
                        )
                        Text("拖动图片可调整显示位置")
                            .font(.caption)
                            .foregroundColor(.gray)
                        HStack(spacing: 12) {
                            Button("点击更换图片") {
                                showImagePicker = true
                            }
                            .font(.caption)
                            .foregroundColor(dataStore.storeData.themeColor.toColor())
                            Button("删除图片") {
                                productImage = nil
                                hasChanges = true
                            }
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                        }
                    } else {
                        Button(action: {
                            showImagePicker = true
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                    .frame(width: cardWidth, height: cardWidth * 0.9)
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 30))
                                        .foregroundColor(dataStore.storeData.themeColor.toColor())
                                    Text("点击添加图片")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                
                HStack {
                    Text("名称")
                        .foregroundColor(.gray)
                    TextField("商品名称", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: name) { _ in hasChanges = true }
                }
                
                HStack {
                    Text("价格")
                        .foregroundColor(.gray)
                    TextField("商品价格", text: $price)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: price) { _ in hasChanges = true }
                }
                
                HStack {
                    Text("原价")
                        .foregroundColor(.gray)
                    TextField("原价（留空不显示）", text: $originalPrice)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: originalPrice) { _ in hasChanges = true }
                }
                
                HStack {
                    Text("活动")
                        .foregroundColor(.gray)
                    TextField("活动信息（留空不显示）", text: $promotion)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: promotion) { _ in hasChanges = true }
                }
            }
            
            if !dataStore.storeData.categories.isEmpty {
                Section(header: Text("分类").font(.headline)) {
                    Picker("选择分类", selection: $selectedCategoryId) {
                        ForEach(dataStore.storeData.categories) { category in
                            Text(category.name).tag(category.id as UUID?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedCategoryId) { _ in hasChanges = true }
                    
                    // 显示当前选中的分类
                    HStack {
                        Text("当前选中：")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        if let catId = selectedCategoryId,
                           let cat = dataStore.storeData.categories.first(where: { $0.id == catId }) {
                            Text(cat.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(dataStore.storeData.themeColor.toColor())
                        } else {
                            Text("未选择")
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            
            // 文字标设置
            Section(header: Text("文字标").font(.headline)) {
                if dataStore.storeData.textBadgeOptions.isEmpty {
                    Text("暂无文字标选项，请先在管理后台添加")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Picker("选择文字标", selection: $textBadge) {
                        Text("无").tag("")
                        ForEach(dataStore.storeData.textBadgeOptions) { option in
                            Text(option.name).tag(option.name)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: textBadge) { newValue in
                        hasChanges = true
                        // 只在用户主动切换标签时自动填充选项默认色（排除初始加载）
                        if newValue != product.textBadge,
                           let option = dataStore.storeData.textBadgeOptions.first(where: { $0.name == newValue }) {
                            textBadgeColor = option.color
                        }
                    }
                }
                
                if !textBadge.isEmpty {
                    HStack {
                        Text("颜色：")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        ColorPicker("", selection: Binding(
                            get: { textBadgeColor.toColor() },
                            set: {
                                textBadgeColor = $0.toHex()
                                hasChanges = true
                            }
                        ))
                        .labelsHidden()
                    }
                }
            }
            
            // 热度标设置
            Section(header: Text("热度标").font(.headline)) {
                if dataStore.storeData.hotBadgeOptions.isEmpty {
                    Text("暂无热度标选项，请先在管理后台添加")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Picker("选择热度标", selection: $hotBadge) {
                        Text("无").tag("")
                        ForEach(dataStore.storeData.hotBadgeOptions) { option in
                            Text(option.name).tag(option.name)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: hotBadge) { newValue in
                        hasChanges = true
                        // 只在用户主动切换标签时自动填充选项默认色
                        if newValue != product.hotBadge,
                           let option = dataStore.storeData.hotBadgeOptions.first(where: { $0.name == newValue }) {
                            hotBadgeColor = option.color
                        }
                    }
                }
                
                if !hotBadge.isEmpty {
                    HStack {
                        Text("颜色：")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        ColorPicker("", selection: Binding(
                            get: { hotBadgeColor.toColor() },
                            set: {
                                hotBadgeColor = $0.toHex()
                                hasChanges = true
                            }
                        ))
                        .labelsHidden()
                    }
                }
            }
            
            Section {
                Button(action: saveChanges) {
                    Text(hasChanges ? "保存修改" : "未做修改")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(hasChanges ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(hasChanges ? dataStore.storeData.themeColor.toColor() : Color.gray.opacity(0.3))
                        .cornerRadius(10)
                }
                .disabled(!hasChanges)
            }
        }
        .navigationTitle("编辑商品")
        .onAppear(perform: loadProduct)
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(selectedImage: $productImage, onImagePicked: { image in
                self.productImage = image
                hasChanges = true
            })
        }
    }
    
    private func loadProduct() {
        // 防止重复加载
        guard !isLoaded else { return }
        isLoaded = true
        
        name = product.name
        price = product.price
        originalPrice = product.originalPrice
        promotion = product.promotion
        description = product.description
        selectedCategoryId = product.categoryId ?? dataStore.storeData.categories.first?.id
        productImage = product.image
        imageOffsetX = product.imageOffsetX
        imageOffsetY = product.imageOffsetY
        textBadge = product.textBadge
        textBadgeColor = product.textBadgeColor
        hotBadge = product.hotBadge
        hotBadgeColor = product.hotBadgeColor
    }
    
    private func saveChanges() {
        let imageData = productImage?.jpegData(compressionQuality: 0.8)
        
        let updated = Product(
            id: product.id,
            name: name.trimmingCharacters(in: .whitespaces),
            price: price.trimmingCharacters(in: .whitespaces),
            originalPrice: originalPrice.trimmingCharacters(in: .whitespaces),
            categoryId: selectedCategoryId,
            imageData: imageData,
            description: description.trimmingCharacters(in: .whitespaces),
            imageOffsetX: imageOffsetX,
            imageOffsetY: imageOffsetY,
            promotion: promotion.trimmingCharacters(in: .whitespaces),
            textBadge: textBadge,
            textBadgeColor: textBadgeColor,
            hotBadge: hotBadge,
            hotBadgeColor: hotBadgeColor
        )
        
        dataStore.updateProduct(updated)
        presentationMode.wrappedValue.dismiss()
    }
}
