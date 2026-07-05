import SwiftUI

// MARK: - 添加商品视图

struct AddProductView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = ""
    @State private var price: String = ""
    @State private var description: String = ""
    @State private var selectedCategoryId: UUID?
    @State private var productImage: UIImage?
    @State private var showImagePicker = false
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !price.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        Form {
            Section(header: Text("商品信息").font(.headline)) {
                // 图片选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("商品图片：")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        showImagePicker = true
                    }) {
                        if let image = productImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 180)
                                .clipped()
                                .cornerRadius(8)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                    .frame(height: 120)
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 30))
                                        .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.6))
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
                
                VStack(alignment: .leading) {
                    Text("描述")
                        .foregroundColor(.gray)
                    TextEditor(text: $description)
                        .frame(minHeight: 60)
                        .padding(4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
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
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            Section {
                Button(action: saveProduct) {
                    Text("添加商品")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(isFormValid ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isFormValid ? Color(red: 0.6, green: 0.2, blue: 0.6) : Color.gray.opacity(0.3))
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
            categoryId: catId,
            imageData: imageData,
            description: description.trimmingCharacters(in: .whitespaces)
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
    @State private var price: String = ""
    @State private var description: String = ""
    @State private var selectedCategoryId: UUID?
    @State private var productImage: UIImage?
    @State private var showImagePicker = false
    @State private var hasChanges = false
    
    var body: some View {
        Form {
            Section(header: Text("商品信息").font(.headline)) {
                // 图片
                VStack(alignment: .leading, spacing: 8) {
                    Text("商品图片（点击更换）：")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        showImagePicker = true
                    }) {
                        if let image = productImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 180)
                                .clipped()
                                .cornerRadius(8)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                    .frame(height: 120)
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 30))
                                        .foregroundColor(Color(red: 0.6, green: 0.2, blue: 0.6))
                                    Text("点击添加图片")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    
                    if productImage != nil {
                        Button("删除图片") {
                            productImage = nil
                            hasChanges = true
                        }
                        .foregroundColor(.red)
                        .font(.system(size: 14))
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
                
                VStack(alignment: .leading) {
                    Text("描述")
                        .foregroundColor(.gray)
                    TextEditor(text: $description)
                        .frame(minHeight: 60)
                        .padding(4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: description) { _ in hasChanges = true }
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
                }
            }
            
            Section {
                Button(action: saveChanges) {
                    Text(hasChanges ? "保存修改" : "未做修改")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(hasChanges ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(hasChanges ? Color(red: 0.6, green: 0.2, blue: 0.6) : Color.gray.opacity(0.3))
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
        name = product.name
        price = product.price
        description = product.description
        selectedCategoryId = product.categoryId ?? dataStore.storeData.categories.first?.id
        productImage = product.image
    }
    
    private func saveChanges() {
        let imageData = productImage?.jpegData(compressionQuality: 0.8)
        
        let updated = Product(
            id: product.id,
            name: name.trimmingCharacters(in: .whitespaces),
            price: price.trimmingCharacters(in: .whitespaces),
            categoryId: selectedCategoryId,
            imageData: imageData,
            description: description.trimmingCharacters(in: .whitespaces)
        )
        
        dataStore.updateProduct(updated)
        presentationMode.wrappedValue.dismiss()
    }
}
