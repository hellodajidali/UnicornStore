import SwiftUI
import UIKit

// MARK: - 自动存盘去抖

final class Debouncer {
    private var work: DispatchWorkItem?

    func run(after delay: TimeInterval, _ block: @escaping () -> Void) {
        work?.cancel()
        let item = DispatchWorkItem(block: block)
        work = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }
}

// MARK: - 主界面

struct EditorView: View {

    enum Tool: String, CaseIterable, Identifiable {
        case size, weight, color, align, spacing, sticker, bg

        var id: String { rawValue }

        var title: String {
            switch self {
            case .size: return "字号"
            case .weight: return "粗细"
            case .color: return "颜色"
            case .align: return "对齐"
            case .spacing: return "行距"
            case .sticker: return "贴图"
            case .bg: return "背景"
            }
        }

        var icon: String {
            switch self {
            case .size: return "textformat.size"
            case .weight: return "bold"
            case .color: return "paintpalette"
            case .align: return "text.alignleft"
            case .spacing: return "arrow.up.and.down"
            case .sticker: return "photo.on.rectangle"
            case .bg: return "square.fill"
            }
        }
    }

    @ObservedObject var store = PosterStore.shared
    @StateObject private var model = RichTextModel()
    @State private var saver = Debouncer()

    @State private var activeTool: Tool = .size
    @State private var showTemplates = false
    @State private var showPhotoPicker = false
    @State private var shareImage: UIImage? = nil
    @State private var showShareSheet = false
    @State private var showNewConfirm = false
    @State private var selectedSticker: UUID? = nil
    @State private var didSetup = false

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    canvasArea
                    bannerArea
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 14)
            }
            Divider()
            bottomBar
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .onAppear(perform: setup)
        .onDisappear(perform: persist)
        .onChange(of: model.textVersion) { _ in scheduleSave() }
        .sheet(isPresented: $showTemplates) {
            TemplateListView(store: store,
                             onPick: { template in loadTemplate(template) },
                             onSaveCurrent: { name in
                                 persist()
                                 store.addTemplate(name: name, from: store.poster)
                             })
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerView(onPicked: { image in
                store.addSticker(image: image)
                selectedSticker = store.poster.stickers.last?.id
                activeTool = .sticker
            })
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheetView(items: [image])
            }
        }
        .alert(isPresented: $showNewConfirm) {
            Alert(title: Text("清空画布？"),
                  message: Text("文字和贴图都会清空，已保存的模板不受影响。"),
                  primaryButton: .destructive(Text("清空")) {
                      store.newBlank()
                      let p = store.poster
                      model.load(p.attributed, size: p.defaultSize, weight: p.defaultWeight, hex: p.textHex, lineSpacing: p.lineSpacing)
                      selectedSticker = nil
                  },
                  secondaryButton: .cancel(Text("取消")))
        }
    }

    // MARK: - 顶栏

    private var topBar: some View {
        HStack(spacing: 10) {
            Button(action: {
                dismissKeyboard()
                showTemplates = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.doc")
                    Text("模板")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
            }
            .buttonStyle(BorderlessButtonStyle())

            Spacer()

            Text("图文海报")
                .font(.system(size: 17, weight: .semibold))

            Spacer()

            Button(action: { dismissKeyboard() }) {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(BorderlessButtonStyle())

            Button(action: makeImage) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                    Text("生成")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color(hex: "#07C160"))
                .cornerRadius(16)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - 画布

    private var canvasWidth: CGFloat {
        let screenW = UIScreen.main.bounds.width - 24
        let maxHeight = UIScreen.main.bounds.height * 0.58
        if let factor = store.poster.ratio.heightFactor {
            return min(screenW, maxHeight / factor)
        }
        return screenW
    }

    private var canvasHeight: CGFloat {
        let w = canvasWidth
        let pad = w * store.poster.paddingRatio
        if let factor = store.poster.ratio.heightFactor {
            return (w * factor).rounded()
        }
        let textH = PosterRenderer.textHeight(model.attributed, width: w - pad * 2)
        return max(120, (textH + pad * 2).rounded())
    }

    private var overflowScale: CGFloat {
        return PosterRenderer.fitScale(store.poster, width: canvasWidth)
    }

    private var canvasArea: some View {
        let w = canvasWidth
        let h = canvasHeight
        let pad = w * store.poster.paddingRatio
        return ZStack(alignment: .topLeading) {
            backgroundView
            RichTextEditor(model: model, lineSpacing: store.poster.lineSpacing)
                .padding(EdgeInsets(top: pad, leading: pad, bottom: pad, trailing: pad))
            if model.attributed.length == 0 {
                Text("在这里输入文字")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: store.poster.textHex).opacity(0.28))
                    .padding(pad)
                    .allowsHitTesting(false)
            }
            StickerLayer(store: store,
                         canvas: CGSize(width: w, height: h),
                         selectedId: $selectedSticker)
        }
        .frame(width: w, height: h)
        .clipped()
        .cornerRadius(6)
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
    }

    @ViewBuilder private var backgroundView: some View {
        if store.poster.gradient {
            LinearGradient(gradient: Gradient(colors: [Color(hex: store.poster.bgHex),
                                                       Color(hex: store.poster.bg2Hex)]),
                           startPoint: .top,
                           endPoint: .bottom)
        } else {
            Color(hex: store.poster.bgHex)
        }
    }

    @ViewBuilder private var bannerArea: some View {
        if overflowScale < 0.995 {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 13))
                Text("文字超出画布，导出时会自动缩小到 \(Int(overflowScale * 100))%")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer(minLength: 0)
                Button(action: { model.scaleAll(by: overflowScale) }) {
                    Text("一键适配")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.10))
            .cornerRadius(8)
        }
    }

    // MARK: - 底部工具栏

    private var bottomBar: some View {
        VStack(spacing: 8) {
            toolPanel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Tool.allCases) { tool in
                        toolButton(tool)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }

    private func toolButton(_ tool: Tool) -> some View {
        Button(action: {
            activeTool = tool
            if tool == .sticker || tool == .bg {
                dismissKeyboard()
            }
            if tool == .sticker && selectedSticker == nil {
                selectedSticker = store.poster.stickers.last?.id
            }
        }) {
            VStack(spacing: 3) {
                Image(systemName: tool.icon)
                    .font(.system(size: 15))
                Text(tool.title)
                    .font(.system(size: 11))
            }
            .foregroundColor(activeTool == tool ? .white : Color.primary)
            .frame(width: 54, height: 46)
            .background(activeTool == tool ? Color.accentColor : Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(BorderlessButtonStyle())
    }

    @ViewBuilder private var toolPanel: some View {
        switch activeTool {
        case .size: sizePanel
        case .weight: weightPanel
        case .color: colorPanel
        case .align: alignPanel
        case .spacing: spacingPanel
        case .sticker: stickerPanel
        case .bg: bgPanel
        }
    }

    private var sizePanel: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Button(action: { model.applySize(model.currentSize - 2) }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(BorderlessButtonStyle())

                Slider(value: Binding(get: { Double(model.currentSize) },
                                      set: { model.applySize(CGFloat(($0).rounded())) }),
                       in: 8...96)

                Button(action: { model.applySize(model.currentSize + 2) }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(BorderlessButtonStyle())

                Text("\(Int(model.currentSize))")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 28)
            }
            Text(model.hasSelection ? "已选中 \(model.selectionLength) 个字：只改选中的部分" : "没有选中：改全部文字")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
    }

    private var weightPanel: some View {
        HStack(spacing: 8) {
            ForEach(PosterWeight.allCases) { weight in
                Button(action: { model.applyWeight(weight) }) {
                    Text(weight.title)
                        .font(.system(size: 14, weight: previewFontWeight(weight)))
                        .foregroundColor(model.currentWeight == weight.rawValue ? .white : Color.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(model.currentWeight == weight.rawValue ? Color.accentColor : Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.horizontal, 12)
    }

    private var colorPanel: some View {
        HStack(spacing: 10) {
            Text("颜色")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presetColors, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 26, height: 26)
                            .overlay(Circle().stroke(Color.gray.opacity(0.35), lineWidth: hex == "#FFFFFF" ? 1 : 0))
                            .overlay(Circle().stroke(Color.accentColor,
                                                     lineWidth: model.currentColorHex.uppercased() == hex.uppercased() ? 2.5 : 0))
                            .onTapGesture { model.applyColor(hex) }
                    }
                }
                .padding(.vertical, 2)
            }
            ColorPicker("", selection: Binding(get: { Color(hex: model.currentColorHex) },
                                               set: { model.applyColor($0.hexString) }))
                .labelsHidden()
        }
        .padding(.horizontal, 14)
    }

    private var alignPanel: some View {
        HStack(spacing: 8) {
            alignButton(index: 0, title: "左对齐", icon: "text.alignleft")
            alignButton(index: 1, title: "居中", icon: "text.aligncenter")
            alignButton(index: 2, title: "右对齐", icon: "text.alignright")
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
    }

    private func alignButton(index: Int, title: String, icon: String) -> some View {
        Button(action: { model.applyAlign(index) }) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 15))
                Text(title).font(.system(size: 11))
            }
            .foregroundColor(model.currentAlign == index ? .white : Color.primary)
            .frame(width: 64, height: 44)
            .background(model.currentAlign == index ? Color.accentColor : Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(BorderlessButtonStyle())
    }

    private var spacingPanel: some View {
        HStack(spacing: 10) {
            Text("行距")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Slider(value: Binding(get: { Double(store.poster.lineSpacing) },
                                  set: { value in
                                      let v = CGFloat((value).rounded())
                                      model.applyLineSpacing(v)
                                      store.mutatePoster { $0.lineSpacing = v }
                                  }),
                   in: 0...30)
            Text("\(Int(store.poster.lineSpacing))")
                .font(.system(size: 13, weight: .medium))
                .frame(width: 28)
        }
        .padding(.horizontal, 14)
    }

    private var stickerPanel: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Button(action: { showPhotoPicker = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("添加贴图")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.accentColor)
                    .cornerRadius(14)
                }
                .buttonStyle(BorderlessButtonStyle())

                Spacer(minLength: 0)

                if let sid = selectedSticker {
                    Button(action: { store.bringSticker(sid, toFront: true) }) {
                        Image(systemName: "arrow.up.to.line")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(BorderlessButtonStyle())

                    Button(action: {
                        store.deleteSticker(sid)
                        selectedSticker = nil
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 15))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }

            if let sid = selectedSticker, let item = stickerItem(sid) {
                HStack(spacing: 10) {
                    Text("大小")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Slider(value: Binding(get: { Double(item.widthRatio) },
                                          set: { value in
                                              store.updateSticker(sid) { $0.widthRatio = CGFloat(value) }
                                          }),
                           in: 0.05...1.2)
                }
                HStack(spacing: 10) {
                    Text("旋转")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Slider(value: Binding(get: { item.rotation },
                                          set: { value in
                                              store.updateSticker(sid) { $0.rotation = value }
                                          }),
                           in: -180...180)
                    Text("\(Int(item.rotation))°")
                        .font(.system(size: 12))
                        .frame(width: 40)
                }
            } else {
                Text("点画布里的图片可选中，拖动移动，双指缩放")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
    }

    private var bgPanel: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CanvasRatio.allCases) { ratio in
                        Button(action: { store.mutatePoster { $0.ratioRaw = ratio.rawValue } }) {
                            Text(ratio.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(store.poster.ratioRaw == ratio.rawValue ? .white : Color.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(store.poster.ratioRaw == ratio.rawValue ? Color.accentColor : Color(.secondarySystemBackground))
                                .cornerRadius(12)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                .padding(.vertical, 2)
            }

            HStack(spacing: 12) {
                Text("背景色")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                ColorPicker("", selection: Binding(get: { Color(hex: store.poster.bgHex) },
                                                   set: { newColor in
                                                       store.mutatePoster { $0.bgHex = newColor.hexString }
                                                   }))
                    .labelsHidden()

                Text("渐变")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Toggle("", isOn: Binding(get: { store.poster.gradient },
                                         set: { value in
                                             store.mutatePoster { $0.gradient = value }
                                         }))
                    .labelsHidden()
                    .scaleEffect(0.8)

                if store.poster.gradient {
                    ColorPicker("", selection: Binding(get: { Color(hex: store.poster.bg2Hex) },
                                                       set: { newColor in
                                                           store.mutatePoster { $0.bg2Hex = newColor.hexString }
                                                       }))
                        .labelsHidden()
                }

                Spacer(minLength: 0)

                Button(action: { showNewConfirm = true }) {
                    Text("清空")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                }
                .buttonStyle(BorderlessButtonStyle())
            }

            HStack(spacing: 10) {
                Text("边距")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Slider(value: Binding(get: { Double(store.poster.paddingRatio) },
                                      set: { value in
                                          store.mutatePoster { $0.paddingRatio = CGFloat(value) }
                                      }),
                       in: 0.03...0.18)
                Text("\(Int(store.poster.paddingRatio * 100))%")
                    .font(.system(size: 12))
                    .frame(width: 40)
            }
        }
        .padding(.horizontal, 14)
    }

    // MARK: - 动作

    private func setup() {
        guard !didSetup else { return }
        didSetup = true
        let p = store.poster
        model.load(p.attributed,
                   size: p.defaultSize,
                   weight: p.defaultWeight,
                   hex: p.textHex,
                   lineSpacing: p.lineSpacing)
        activeTool = .size
        selectedSticker = p.stickers.last?.id
    }

    private func loadTemplate(_ template: Template) {
        let p = template.data
        store.poster = p
        model.load(p.attributed,
                   size: p.defaultSize,
                   weight: p.defaultWeight,
                   hex: p.textHex,
                   lineSpacing: p.lineSpacing)
        selectedSticker = nil
    }

    private func scheduleSave() {
        saver.run(after: 0.7) {
            persist()
        }
    }

    private func persist() {
        var p = store.poster
        p.setText(model.attributed)
        p.defaultSize = model.defaultSize
        p.defaultWeight = model.defaultWeight
        p.textHex = model.textHex
        p.lineSpacing = model.lineSpacing
        store.poster = p
    }

    private func makeImage() {
        dismissKeyboard()
        persist()
        var p = store.poster
        p.setText(model.attributed)
        let image = PosterRenderer.render(p, width: canvasWidth, scale: 3)
        shareImage = image
        showShareSheet = true
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }

    private func stickerItem(_ id: UUID) -> StickerItem? {
        return store.poster.stickers.first(where: { $0.id == id })
    }

    private func previewFontWeight(_ weight: PosterWeight) -> Font.Weight {
        switch weight {
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }

    private var presetColors: [String] {
        return ["#222222", "#FFFFFF", "#E53935", "#FB8C00", "#FFD600",
                "#43A047", "#1E88E5", "#8E24AA", "#6D4C41", "#9E9E9E"]
    }
}
