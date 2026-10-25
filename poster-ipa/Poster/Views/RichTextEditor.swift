import SwiftUI
import UIKit

// MARK: - 富文本编辑模型（支持局部/全局字号、粗细、颜色）

final class RichTextModel: ObservableObject {

    /// 每次文字内容变化 +1（用于自动存草稿）
    @Published var textVersion: Int = 0
    /// 外部替换内容时 +1（用于让 UITextView 同步）
    @Published var revision: Int = 0

    @Published var hasSelection: Bool = false
    @Published var selectionLength: Int = 0
    @Published var currentSize: CGFloat = 20
    @Published var currentWeight: Int = 1
    @Published var currentColorHex: String = "#222222"
    @Published var currentAlign: Int = 0

    var attributed: NSAttributedString = NSAttributedString()
    var lineSpacing: CGFloat = 6
    var defaultSize: CGFloat = 20
    var defaultWeight: Int = 1
    var textHex: String = "#222222"

    weak var textView: UITextView?
    var suppress = false

    // MARK: - 载入

    func load(_ attr: NSAttributedString, size: CGFloat, weight: Int, hex: String, lineSpacing: CGFloat) {
        attributed = attr
        defaultSize = size
        defaultWeight = weight
        textHex = hex
        self.lineSpacing = lineSpacing
        currentSize = size
        currentWeight = weight
        currentColorHex = hex
        revision += 1
    }

    func typingAttrs() -> [NSAttributedString.Key: Any] {
        let font = UIFont.systemFont(ofSize: defaultSize, weight: PosterWeight.from(defaultWeight).uiWeight)
        let para = NSMutableParagraphStyle()
        para.lineSpacing = lineSpacing
        para.alignment = alignment(for: currentAlign)
        return [
            .font: font,
            .foregroundColor: UIColor(hex: textHex),
            .paragraphStyle: para,
            kPosterWeight: defaultWeight
        ]
    }

    func alignment(for index: Int) -> NSTextAlignment {
        switch index {
        case 1: return .center
        case 2: return .right
        default: return .left
        }
    }

    func alignIndex(for alignment: NSTextAlignment) -> Int {
        switch alignment {
        case .center: return 1
        case .right: return 2
        default: return 0
        }
    }

    // MARK: - 编辑回调

    func handleEdit(_ tv: UITextView) {
        attributed = tv.attributedText
        textVersion += 1
        refreshFromSelection()
    }

    func refreshFromSelection() {
        guard let tv = textView else { return }
        let length = tv.textStorage.length
        let sel = tv.selectedRange
        hasSelection = sel.length > 0
        selectionLength = sel.length
        guard length > 0 else { return }
        let loc = min(max(0, sel.location), length - 1)
        let storage = tv.textStorage
        if let font = storage.attribute(.font, at: loc, effectiveRange: nil) as? UIFont {
            currentSize = font.pointSize
        }
        currentWeight = weightIndex(in: storage, at: loc).rawValue
        if let color = storage.attribute(.foregroundColor, at: loc, effectiveRange: nil) as? UIColor {
            currentColorHex = color.hexString
        }
        if let para = storage.attribute(.paragraphStyle, at: loc, effectiveRange: nil) as? NSParagraphStyle {
            currentAlign = alignIndex(for: para.alignment)
        }
    }

    // MARK: - 工具

    private func targetRange(_ tv: UITextView) -> NSRange {
        let sel = tv.selectedRange
        if sel.length > 0 { return sel }
        return NSRange(location: 0, length: tv.textStorage.length)
    }

    private func weightIndex(in storage: NSTextStorage, at location: Int) -> PosterWeight {
        if location < 0 || location >= storage.length { return PosterWeight.from(defaultWeight) }
        if let n = storage.attribute(kPosterWeight, at: location, effectiveRange: nil) as? NSNumber {
            return PosterWeight.from(n.intValue)
        }
        return PosterWeight.from(defaultWeight)
    }

    /// 收集 [范围, 字号, 粗细]
    private func fontRuns(in storage: NSTextStorage, range: NSRange) -> [(NSRange, CGFloat, PosterWeight)] {
        var out: [(NSRange, CGFloat, PosterWeight)] = []
        let end = range.location + range.length
        var loc = range.location
        while loc < end {
            var eff = NSRange(location: 0, length: 0)
            let font = storage.attribute(.font, at: loc, effectiveRange: &eff) as? UIFont
            if eff.length <= 0 { break }
            let sub = NSIntersectionRange(eff, range)
            if sub.length > 0 {
                out.append((sub, font?.pointSize ?? defaultSize, weightIndex(in: storage, at: loc)))
            }
            loc = eff.location + eff.length
        }
        return out
    }

    private func commit(_ tv: UITextView) {
        suppress = true
        attributed = tv.attributedText
        suppress = false
        textVersion += 1
        refreshFromSelection()
    }

    // MARK: - 应用样式（有选区=只改选中，无选区=改全部）

    func applySize(_ size: CGFloat) {
        let clamped = min(96, max(8, size))
        guard let tv = textView, tv.textStorage.length > 0 else {
            currentSize = clamped
            defaultSize = clamped
            textView?.typingAttributes = typingAttrs()
            return
        }
        let range = targetRange(tv)
        let runs = fontRuns(in: tv.textStorage, range: range)
        let storage = tv.textStorage
        storage.beginEditing()
        for (sub, _, weight) in runs {
            let font = UIFont.systemFont(ofSize: clamped, weight: weight.uiWeight)
            storage.addAttribute(.font, value: font, range: sub)
            storage.addAttribute(kPosterWeight, value: weight.rawValue, range: sub)
        }
        storage.endEditing()
        currentSize = clamped
        if range.location == 0 && range.length == storage.length {
            defaultSize = clamped
        }
        tv.typingAttributes = typingAttrs()
        commit(tv)
    }

    func applyWeight(_ weight: PosterWeight) {
        guard let tv = textView, tv.textStorage.length > 0 else {
            currentWeight = weight.rawValue
            defaultWeight = weight.rawValue
            textView?.typingAttributes = typingAttrs()
            return
        }
        let range = targetRange(tv)
        let runs = fontRuns(in: tv.textStorage, range: range)
        let storage = tv.textStorage
        storage.beginEditing()
        for (sub, size, _) in runs {
            let font = UIFont.systemFont(ofSize: size, weight: weight.uiWeight)
            storage.addAttribute(.font, value: font, range: sub)
            storage.addAttribute(kPosterWeight, value: weight.rawValue, range: sub)
        }
        storage.endEditing()
        currentWeight = weight.rawValue
        if range.location == 0 && range.length == storage.length {
            defaultWeight = weight.rawValue
        }
        tv.typingAttributes = typingAttrs()
        commit(tv)
    }

    func applyColor(_ hex: String) {
        guard let tv = textView, tv.textStorage.length > 0 else {
            currentColorHex = hex
            textHex = hex
            textView?.typingAttributes = typingAttrs()
            return
        }
        let range = targetRange(tv)
        let storage = tv.textStorage
        storage.beginEditing()
        storage.addAttribute(.foregroundColor, value: UIColor(hex: hex), range: range)
        storage.endEditing()
        currentColorHex = hex
        if range.location == 0 && range.length == storage.length {
            textHex = hex
        }
        tv.typingAttributes = typingAttrs()
        commit(tv)
    }

    func applyAlign(_ index: Int) {
        guard let tv = textView else {
            currentAlign = index
            return
        }
        currentAlign = index
        let storage = tv.textStorage
        let full = NSRange(location: 0, length: storage.length)
        guard full.length > 0 else { return }
        storage.beginEditing()
        for (sub, _, _) in paragraphRuns(in: storage, range: full) {
            let para = NSMutableParagraphStyle()
            para.alignment = alignment(for: index)
            para.lineSpacing = lineSpacing
            storage.addAttribute(.paragraphStyle, value: para, range: sub)
        }
        storage.endEditing()
        tv.typingAttributes = typingAttrs()
        commit(tv)
    }

    func applyLineSpacing(_ spacing: CGFloat) {
        lineSpacing = spacing
        guard let tv = textView else { return }
        let storage = tv.textStorage
        let full = NSRange(location: 0, length: storage.length)
        guard full.length > 0 else { return }
        storage.beginEditing()
        for (sub, alignmentValue, _) in paragraphRuns(in: storage, range: full) {
            let para = NSMutableParagraphStyle()
            para.alignment = alignmentValue
            para.lineSpacing = spacing
            storage.addAttribute(.paragraphStyle, value: para, range: sub)
        }
        storage.endEditing()
        tv.typingAttributes = typingAttrs()
        currentAlign = alignIndex(for: alignment(for: currentAlign))
        commit(tv)
    }

    private func paragraphRuns(in storage: NSTextStorage, range: NSRange) -> [(NSRange, NSTextAlignment, CGFloat)] {
        var out: [(NSRange, NSTextAlignment, CGFloat)] = []
        let end = range.location + range.length
        var loc = range.location
        while loc < end {
            var eff = NSRange(location: 0, length: 0)
            let para = storage.attribute(.paragraphStyle, at: loc, effectiveRange: &eff) as? NSParagraphStyle
            if eff.length <= 0 { break }
            let sub = NSIntersectionRange(eff, range)
            if sub.length > 0 {
                out.append((sub, para?.alignment ?? alignment(for: currentAlign), para?.lineSpacing ?? lineSpacing))
            }
            loc = eff.location + eff.length
        }
        return out
    }

    /// 一键适配：全部文字按比例缩小
    func scaleAll(by factor: CGFloat) {
        guard let tv = textView, tv.textStorage.length > 0, factor > 0 else { return }
        let range = NSRange(location: 0, length: tv.textStorage.length)
        let runs = fontRuns(in: tv.textStorage, range: range)
        let storage = tv.textStorage
        storage.beginEditing()
        for (sub, size, weight) in runs {
            let font = UIFont.systemFont(ofSize: max(8, size * factor), weight: weight.uiWeight)
            storage.addAttribute(.font, value: font, range: sub)
            storage.addAttribute(kPosterWeight, value: weight.rawValue, range: sub)
        }
        storage.endEditing()
        if let first = fontRuns(in: storage, range: NSRange(location: 0, length: 1)).first {
            currentSize = first.1
            defaultSize = first.1
        }
        commit(tv)
    }
}

// MARK: - UITextView 封装

struct RichTextEditor: UIViewRepresentable {
    @ObservedObject var model: RichTextModel
    var lineSpacing: CGFloat

    func makeCoordinator() -> Coordinator {
        return Coordinator(model: model)
    }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.backgroundColor = .clear
        tv.isOpaque = false
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.isEditable = true
        tv.isScrollEnabled = true
        tv.alwaysBounceVertical = true
        tv.keyboardDismissMode = .interactive
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.spellCheckingType = .no
        tv.smartQuotesType = .no
        tv.smartDashesType = .no
        tv.delegate = context.coordinator
        tv.attributedText = model.attributed
        tv.typingAttributes = model.typingAttrs()
        model.textView = tv
        context.coordinator.appliedRevision = model.revision
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        model.textView = tv
        if context.coordinator.appliedRevision != model.revision {
            context.coordinator.appliedRevision = model.revision
            model.suppress = true
            tv.attributedText = model.attributed
            tv.typingAttributes = model.typingAttrs()
            model.suppress = false
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        let model: RichTextModel
        var appliedRevision: Int = -1

        init(model: RichTextModel) {
            self.model = model
        }

        func textViewDidChange(_ textView: UITextView) {
            guard !model.suppress else { return }
            model.handleEdit(textView)
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !model.suppress else { return }
            model.refreshFromSelection()
        }
    }
}
