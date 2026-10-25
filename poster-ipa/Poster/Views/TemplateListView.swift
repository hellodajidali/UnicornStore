import SwiftUI

// MARK: - 文字模板列表

struct TemplateListView: View {
    @ObservedObject var store: PosterStore
    var onPick: (Template) -> Void
    var onSaveCurrent: (String) -> Void

    @Environment(\.presentationMode) var presentationMode

    @State private var showNameSheet = false
    @State private var renameTarget: Template? = nil
    @State private var deleteTarget: Template? = nil
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    saveCurrentButton

                    if store.templates.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 34))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("还没有模板")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            Text("把常发的文案存成模板，下次点一下就出来")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 50)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(store.templates.enumerated()), id: \.element.id) { index, template in
                                templateRow(template)
                                if index < store.templates.count - 1 {
                                    Divider().padding(.leading, 14)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationBarTitle("文字模板", displayMode: .inline)
            .navigationBarItems(leading: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showNameSheet) {
            TextInputSheet(title: "模板名称",
                           placeholder: "比如：今日特价 / 新品到货",
                           text: "",
                           onSave: { name in
                               onSaveCurrent(name)
                           })
        }
        .sheet(item: $renameTarget) { target in
            TextInputSheet(title: "重命名",
                           placeholder: "模板名称",
                           text: target.name,
                           onSave: { name in
                               store.renameTemplate(target.id, name: name)
                           })
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(title: Text("删除模板？"),
                  message: Text("「\(deleteTarget?.name ?? "")」删除后不能恢复。"),
                  primaryButton: .cancel(Text("取消")),
                  secondaryButton: .destructive(Text("删除")) {
                      if let target = deleteTarget {
                          store.deleteTemplate(target.id)
                      }
                      deleteTarget = nil
                  })
        }
    }

    private var saveCurrentButton: some View {
        Button(action: { showNameSheet = true }) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                Text("把当前画布存为模板")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .cornerRadius(10)
        }
        .buttonStyle(BorderlessButtonStyle())
    }

    private func templateRow(_ template: Template) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(template.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    if !template.data.stickers.isEmpty {
                        Text("\(template.data.stickers.count) 贴图")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                    Text(template.data.ratio.title)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(4)
                }
                Text(template.plainPreview)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onPick(template)
                presentationMode.wrappedValue.dismiss()
            }

            Menu {
                Button(action: { renameTarget = template }) {
                    Label("重命名", systemImage: "pencil")
                }
                Button(action: { store.updateTemplate(template.id, data: store.poster) }) {
                    Label("用当前内容覆盖", systemImage: "arrow.triangle.2.circlepath")
                }
                Button(action: {
                    deleteTarget = template
                    showDeleteAlert = true
                }) {
                    Label("删除", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                    .frame(width: 40, height: 40)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - 文字输入弹窗（iOS 14 Alert 不支持 TextField）

struct TextInputSheet: View {
    let title: String
    let placeholder: String
    let onSave: (String) -> Void

    @State private var text: String
    @Environment(\.presentationMode) var presentationMode

    init(title: String, placeholder: String, text: String, onSave: @escaping (String) -> Void) {
        self.title = title
        self.placeholder = placeholder
        self.onSave = onSave
        self._text = State(initialValue: text)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 14) {
                TextField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                Spacer()
            }
            .navigationBarTitle(title, displayMode: .inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !value.isEmpty {
                        onSave(value)
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
