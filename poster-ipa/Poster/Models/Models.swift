import Foundation
import SwiftUI
import UIKit

// MARK: - 文字粗细

enum PosterWeight: Int, CaseIterable, Identifiable {
    case light = 0
    case regular = 1
    case medium = 2
    case semibold = 3
    case bold = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .light: return "细"
        case .regular: return "常规"
        case .medium: return "中"
        case .semibold: return "粗"
        case .bold: return "特粗"
        }
    }

    var uiWeight: UIFont.Weight {
        switch self {
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }

    static func from(_ index: Int) -> PosterWeight {
        return PosterWeight(rawValue: index) ?? .regular
    }
}

/// 自定义属性：记录文字粗细（0-4），保证导出和再次编辑时粗细不丢
let kPosterWeight = NSAttributedString.Key("PosterWeight")

// MARK: - 画布比例

enum CanvasRatio: String, CaseIterable, Identifiable, Codable {
    case r3x4 = "3:4"
    case r4x5 = "4:5"
    case r1x1 = "1:1"
    case r9x16 = "9:16"
    case auto = "auto"

    var id: String { rawValue }

    /// 高度 / 宽度。nil = 自动高度（内容多长图多高）
    var heightFactor: CGFloat? {
        switch self {
        case .r3x4: return 4.0 / 3.0
        case .r4x5: return 5.0 / 4.0
        case .r1x1: return 1.0
        case .r9x16: return 16.0 / 9.0
        case .auto: return nil
        }
    }

    var title: String {
        switch self {
        case .r3x4: return "3:4"
        case .r4x5: return "4:5"
        case .r1x1: return "1:1"
        case .r9x16: return "9:16"
        case .auto: return "自动高度"
        }
    }
}

// MARK: - 贴图

struct StickerItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var imageData: Data
    /// 中心点位置（0-1，相对画布宽高）
    var cx: CGFloat = 0.5
    var cy: CGFloat = 0.5
    /// 宽度（相对画布宽度）
    var widthRatio: CGFloat = 0.35
    /// 旋转角度
    var rotation: Double = 0

    var uiImage: UIImage? {
        return UIImage(data: imageData)
    }

    /// 宽 / 高
    var aspect: CGFloat {
        if let img = uiImage, img.size.height > 0, img.size.width > 0 {
            return img.size.width / img.size.height
        }
        return 1
    }
}

// MARK: - 海报数据（草稿 + 模板共用）

struct PosterData: Codable {
    var richData: Data
    var rtfData: Data
    var plainText: String

    var bgHex: String
    var bg2Hex: String
    var gradient: Bool

    var ratioRaw: String
    var paddingRatio: CGFloat
    var lineSpacing: CGFloat

    var defaultSize: CGFloat
    var defaultWeight: Int
    var textHex: String

    var stickers: [StickerItem]

    enum CodingKeys: String, CodingKey {
        case richData, rtfData, plainText
        case bgHex, bg2Hex, gradient
        case ratioRaw, paddingRatio, lineSpacing
        case defaultSize, defaultWeight, textHex
        case stickers
    }

    init() {
        self.richData = Data()
        self.rtfData = Data()
        self.plainText = ""
        self.bgHex = "#FFFFFF"
        self.bg2Hex = "#FFF3E6"
        self.gradient = false
        self.ratioRaw = CanvasRatio.r3x4.rawValue
        self.paddingRatio = 0.08
        self.lineSpacing = 6
        self.defaultSize = 20
        self.defaultWeight = 1
        self.textHex = "#222222"
        self.stickers = []
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        richData = try c.decodeIfPresent(Data.self, forKey: .richData) ?? Data()
        rtfData = try c.decodeIfPresent(Data.self, forKey: .rtfData) ?? Data()
        plainText = try c.decodeIfPresent(String.self, forKey: .plainText) ?? ""
        bgHex = try c.decodeIfPresent(String.self, forKey: .bgHex) ?? "#FFFFFF"
        bg2Hex = try c.decodeIfPresent(String.self, forKey: .bg2Hex) ?? "#FFF3E6"
        gradient = try c.decodeIfPresent(Bool.self, forKey: .gradient) ?? false
        ratioRaw = try c.decodeIfPresent(String.self, forKey: .ratioRaw) ?? CanvasRatio.r3x4.rawValue
        paddingRatio = try c.decodeIfPresent(CGFloat.self, forKey: .paddingRatio) ?? 0.08
        lineSpacing = try c.decodeIfPresent(CGFloat.self, forKey: .lineSpacing) ?? 6
        defaultSize = try c.decodeIfPresent(CGFloat.self, forKey: .defaultSize) ?? 20
        defaultWeight = try c.decodeIfPresent(Int.self, forKey: .defaultWeight) ?? 1
        textHex = try c.decodeIfPresent(String.self, forKey: .textHex) ?? "#222222"
        stickers = try c.decodeIfPresent([StickerItem].self, forKey: .stickers) ?? []
    }

    var ratio: CanvasRatio {
        return CanvasRatio(rawValue: ratioRaw) ?? .r3x4
    }

    /// 取出带样式的文字
    var attributed: NSAttributedString {
        return RichTextCodec.decode(rich: richData,
                                    rtf: rtfData,
                                    plain: plainText,
                                    size: defaultSize,
                                    hex: textHex,
                                    weight: defaultWeight)
    }

    /// 写入带样式的文字（同时更新富文本、RTF、纯文本三份备份）
    mutating func setText(_ attr: NSAttributedString) {
        let packed = RichTextCodec.encode(attr)
        richData = packed.rich
        rtfData = packed.rtf
        plainText = packed.plain
    }
}

// MARK: - 模板

struct Template: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String = ""
    var data: PosterData = PosterData()
    var createdAt: Date = Date()

    var plainPreview: String {
        let t = data.plainText.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return "（空白模板）" }
        return t.count > 40 ? String(t.prefix(40)) + "…" : t
    }
}

// MARK: - 富文本编解码

enum RichTextCodec {

    static func encode(_ attr: NSAttributedString) -> (rich: Data, rtf: Data, plain: String) {
        let plain = attr.string
        var rich = Data()
        var rtf = Data()
        guard attr.length > 0 else {
            return (rich, rtf, plain)
        }
        if let d = try? NSKeyedArchiver.archivedData(withRootObject: attr, requiringSecureCoding: false) {
            rich = d
        }
        let full = NSRange(location: 0, length: attr.length)
        if let d = try? attr.data(from: full, documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]) {
            rtf = d
        }
        return (rich, rtf, plain)
    }

    static func decode(rich: Data, rtf: Data, plain: String, size: CGFloat, hex: String, weight: Int) -> NSAttributedString {
        if !rich.isEmpty {
            if let a = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: rich) {
                return a
            }
            if let object = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(rich),
               let a = object as? NSAttributedString {
                return a
            }
        }
        if !rtf.isEmpty {
            if let a = try? NSAttributedString(data: rtf,
                                               options: [.documentType: NSAttributedString.DocumentType.rtf],
                                               documentAttributes: nil) {
                return a
            }
        }
        let font = UIFont.systemFont(ofSize: size, weight: PosterWeight.from(weight).uiWeight)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(hex: hex),
            kPosterWeight: weight
        ]
        return NSAttributedString(string: plain, attributes: attrs)
    }
}

// MARK: - 颜色工具

extension UIColor {

    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        if s.count == 3 {
            let r = String(Array(s)[0]), g = String(Array(s)[1]), b = String(Array(s)[2])
            s = r + r + g + g + b + b
        }
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 1
        if s.count == 8 {
            r = CGFloat((value >> 24) & 0xFF) / 255.0
            g = CGFloat((value >> 16) & 0xFF) / 255.0
            b = CGFloat((value >> 8) & 0xFF) / 255.0
            a = CGFloat(value & 0xFF) / 255.0
        } else {
            r = CGFloat((value >> 16) & 0xFF) / 255.0
            g = CGFloat((value >> 8) & 0xFF) / 255.0
            b = CGFloat(value & 0xFF) / 255.0
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if getRed(&r, green: &g, blue: &b, alpha: &a) {
            return String(format: "#%02X%02X%02X",
                          Int((r * 255).rounded()),
                          Int((g * 255).rounded()),
                          Int((b * 255).rounded()))
        }
        return "#000000"
    }
}

extension Color {
    init(hex: String) {
        self.init(UIColor(hex: hex))
    }

    var hexString: String {
        return UIColor(self).hexString
    }
}

// MARK: - 图片压缩

enum ImageTool {

    static func hasAlpha(_ image: UIImage) -> Bool {
        guard let cg = image.cgImage else { return false }
        switch cg.alphaInfo {
        case .first, .last, .premultipliedFirst, .premultipliedLast:
            return true
        default:
            return false
        }
    }

    static func compressedData(_ image: UIImage, maxSide: CGFloat = 900) -> Data? {
        let w = max(1, image.size.width)
        let h = max(1, image.size.height)
        let factor = min(1.0, maxSide / max(w, h))
        let target = CGSize(width: max(1, w * factor), height: max(1, h * factor))
        let renderer = UIGraphicsImageRenderer(size: target)
        let small = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        if hasAlpha(image) {
            return small.pngData()
        }
        return small.jpegData(compressionQuality: 0.85)
    }
}
