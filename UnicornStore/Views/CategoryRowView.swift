import SwiftUI

// MARK: - 分类行视图

struct CategoryRowView: View {
    @EnvironmentObject var dataStore: DataStore
    @Binding var selectedId: UUID?
    
    // 快照分类数组，避免 ForEach 在删除时的 identity 问题
    private var categories: [Category] {
        dataStore.storeData.categories
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedId == category.id ||
                            (selectedId == nil && category.name == "全部分类"),
                        action: {
                            // 使用 DispatchQueue.main.async 避免动画吞掉状态更新
                            DispatchQueue.main.async {
                                if selectedId == category.id {
                                    selectedId = nil
                                } else {
                                    selectedId = category.id
                                }
                            }
                        }
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - 分类标签

struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.name)
                .font(.system(size: isSelected ? category.fontSize + 1 : category.fontSize, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : category.textColor.toColor())
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                        DataStore.shared.storeData.themeColor.toColor() :
                        DataStore.shared.storeData.themeColor.toColor().opacity(0.1)
                )
                .cornerRadius(18)
        }
        .buttonStyle(PlainButtonStyle()) // 避免 Button 默认样式干扰
    }
}

// MARK: - 分类编辑视图（管理后台用）

struct CategoryEditView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var newCategoryName: String = ""
    @State private var editingCategory: Category? = nil
    @State private var editName: String = ""
    @State private var showRenameSheet = false
    @State private var categoryFontSize: CGFloat = 15
    @State private var categoryTextColor: String = "#663399"
    @State private var editingCategoryFontColor: Category? = nil
    @State private var showFontColorSheet = false
    @State private var showDeleteAlert = false
    @State private var categoryToDelete: Category? = nil
    
    private let presetColors = ["#663399", "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#FF8C00", "#20B2AA", "#FF69B4", "#000000", "#808080"]
    
    var body: some View {
        Section(header: Text("分类管理").font(.headline)) {
            VStack(alignment: .leading, spacing: 8) {
                // 分类列表
                let cats = dataStore.storeData.categories
                ForEach(cats) { category in
                    HStack {
                        Text(category.name)
                            .font(.system(size: category.fontSize))
                            .foregroundColor(category.textColor.toColor())
                        
                        Spacer()
                        
                        if category.name != "全部分类" {
                            // 编辑字体和颜色
                            Button(action: {
                                editingCategoryFontColor = category
                                categoryFontSize = category.fontSize
                                categoryTextColor = category.textColor
                                showFontColorSheet = true
                            }) {
                                Image(systemName: "textformat")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            // 编辑名称
                            Button(action: {
                                editingCategory = category
                                editName = category.name
                                showRenameSheet = true
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            // 删除
                            Button(action: {
                                categoryToDelete = category
                                showDeleteAlert = true
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.vertical, 4)
            
            // 添加新分类
            HStack {
                TextField("新分类名称", text: $newCategoryName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        dataStore.addCategory(trimmed)
                        newCategoryName = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
                .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        // 重命名弹窗
        .sheet(isPresented: $showRenameSheet) {
            NavigationView {
                VStack(spacing: 20) {
                    Text("编辑分类名称")
                        .font(.headline)
                        .padding(.top)
                    
                    TextField("输入新名称", text: $editName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .navigationBarItems(
                    leading: Button("取消") {
                        showRenameSheet = false
                    },
                    trailing: Button("保存") {
                        if let cat = editingCategory {
                            let trimmed = editName.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty {
                                dataStore.renameCategory(cat, newName: trimmed)
                            }
                        }
                        showRenameSheet = false
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(dataStore.storeData.themeColor.toColor())
                )
            }
        }
        // 删除确认
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("删除分类"),
                message: Text("确定要删除「\(categoryToDelete?.name ?? "")」吗？该分类下的商品不会自动删除。"),
                primaryButton: .cancel(Text("取消")),
                secondaryButton: .destructive(Text("删除")) {
                    if let cat = categoryToDelete {
                        dataStore.deleteCategory(cat)
                        categoryToDelete = nil
                    }
                }
            )
        }
        // 字体/颜色设置
        .sheet(isPresented: $showFontColorSheet) {
            NavigationView {
                Form {
                    Section(header: Text("字体大小")) {
                        Slider(value: $categoryFontSize, in: 12...24, step: 1)
                        Text("预览：\(Int(categoryFontSize))号字")
                            .font(.system(size: categoryFontSize))
                            .foregroundColor(categoryTextColor.toColor())
                    }
                    
                    Section(header: Text("字体颜色")) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                            ForEach(presetColors, id: \.self) { color in
                                Circle()
                                    .fill(color.toColor())
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(categoryTextColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                                    .onTapGesture {
                                        categoryTextColor = color
                                    }
                            }
                        }
                    }
                    
                    Section {
                        Button("保存设置") {
                            if let cat = editingCategoryFontColor {
                                dataStore.updateCategoryStyle(cat, fontSize: categoryFontSize, textColor: categoryTextColor)
                            }
                            showFontColorSheet = false
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .background(dataStore.storeData.themeColor.toColor())
                        .cornerRadius(10)
                    }
                }
                .navigationTitle("分类样式")
                .navigationBarItems(trailing: Button("取消") {
                    showFontColorSheet = false
                })
            }
        }
    }
}
