import SwiftUI

// MARK: - 分类行视图

struct CategoryRowView: View {
    @EnvironmentObject var dataStore: DataStore
    @Binding var selectedId: UUID?
    
    private var categories: [Category] {
        dataStore.storeData.categories
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories) { category in
                    CategoryChip(
                        name: category.name,
                        isSelected: selectedId == category.id ||
                            (selectedId == nil && category.name == "全部分类"),
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
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
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.system(size: 15, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : Color(red: 0.4, green: 0.15, blue: 0.5))
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                        Color(red: 0.6, green: 0.2, blue: 0.6) :
                        Color(red: 0.95, green: 0.9, blue: 0.98)
                )
                .cornerRadius(18)
        }
    }
}

// MARK: - 分类编辑视图（管理后台用）

struct CategoryEditView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var newCategoryName: String = ""
    @State private var editingCategory: Category? = nil
    @State private var editName: String = ""
    @State private var showEditAlert = false
    
    var body: some View {
        Section(header: Text("分类管理").font(.headline)) {
            VStack(alignment: .leading, spacing: 8) {
                Text("当前分类：")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                ForEach(dataStore.storeData.categories) { category in
                    HStack {
                        Text(category.name)
                            .font(.system(size: 15))
                        
                        Spacer()
                        
                        if category.name != "全部分类" {
                            Button(action: {
                                editingCategory = category
                                editName = category.name
                                showEditAlert = true
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                            }
                            
                            Button(action: {
                                dataStore.deleteCategory(category)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                            }
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
        .alert(isPresented: $showEditAlert) {
            Text("编辑分类名称")
        } message: {
            Text("请输入新的分类名称")
        }
        .onChange(of: showEditAlert) { showing in
            if !showing, let cat = editingCategory {
                let trimmed = editName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    dataStore.renameCategory(cat, newName: trimmed)
                }
            }
        }
    }
}
