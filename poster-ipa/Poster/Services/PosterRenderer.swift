import UIKit

// MARK: - 生成图片（Core Graphics 手动绘制 → UIImage，直接给分享面板）

enum PosterRenderer {

    static func padding(_ p: PosterData, width W: CGFloat) -> CGFloat {
        return W * p.paddingRatio
    }

    static func textHeight(_ attr: NSAttributedString, width: CGFloat) -> CGFloat {
        guard attr.length > 0, width > 10 else { return 0 }
        let rect = attr.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                     options: [.usesLineFragmentOrigin, .usesFontLeading],
                                     context: nil)
        return ceil(rect.height) + 2
    }

    /// 画布尺寸（自动高度模式按文字长度算）
    static func canvasSize(_ p: PosterData, width W: CGFloat) -> CGSize {
        if let factor = p.ratio.heightFactor {
            return CGSize(width: W, height: (W * factor).rounded())
        }
        let pad = padding(p, width: W)
        let h = textHeight(p.attributed, width: W - pad * 2)
        return CGSize(width: W, height: max(120, (h + pad * 2).rounded()))
    }

    /// 固定比例时，文字超出画布需要整体缩小的系数（1 = 不缩）
    static func fitScale(_ p: PosterData, width W: CGFloat) -> CGFloat {
        guard let factor = p.ratio.heightFactor else { return 1 }
        let pad = padding(p, width: W)
        let avail = W * factor - pad * 2
        let attr = p.attributed
        guard attr.length > 0, avail > 20 else { return 1 }
        let textW = W - pad * 2
        if textHeight(attr, width: textW) <= avail { return 1 }
        var s: CGFloat = 1.0
        while s > 0.45 {
            s -= 0.03
            let candidate = scaledAttributed(attr, by: s, lineSpacing: p.lineSpacing * s)
            if textHeight(candidate, width: textW) <= avail { return s }
        }
        return 0.45
    }

    /// 出图。width = 编辑时画布的逻辑宽度（保证和预览断行一致），scale = 分辨率倍数
    static func render(_ p: PosterData, width W: CGFloat, scale: CGFloat = 3) -> UIImage {
        let pad = padding(p, width: W)
        let ratioScale = fitScale(p, width: W)
        let size = canvasSize(p, width: W)
        let textW = W - pad * 2
        let attr = scaledAttributed(p.attributed, by: ratioScale, lineSpacing: p.lineSpacing * ratioScale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { context in
            let cg = context.cgContext
            let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            drawBackground(cg: cg, poster: p, rect: rect)
            if attr.length > 0 {
                let textRect = CGRect(x: pad, y: pad, width: textW, height: max(10, size.height - pad * 2))
                attr.draw(with: textRect,
                          options: [.usesLineFragmentOrigin, .usesFontLeading],
                          context: nil)
            }
            drawStickers(cg: cg, poster: p, size: size)
        }
    }

    // MARK: - 背景

    private static func drawBackground(cg: CGContext, poster p: PosterData, rect: CGRect) {
        let c1 = UIColor(hex: p.bgHex)
        if p.gradient {
            let c2 = UIColor(hex: p.bg2Hex)
            let colors = [c1.cgColor, c2.cgColor] as CFArray
            let locations: [CGFloat] = [0, 1]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: colors,
                                         locations: locations) {
                cg.drawLinearGradient(gradient,
                                      start: CGPoint(x: rect.midX, y: rect.minY),
                                      end: CGPoint(x: rect.midX, y: rect.maxY),
                                      options: [])
                return
            }
        }
        cg.setFillColor(c1.cgColor)
        cg.fill(rect)
    }

    // MARK: - 贴图

    private static func drawStickers(cg: CGContext, poster p: PosterData, size: CGSize) {
        for sticker in p.stickers {
            guard let image = sticker.uiImage else { continue }
            let w = sticker.widthRatio * size.width
            let aspect = image.size.height > 0 ? image.size.width / image.size.height : 1
            let h = w / max(0.05, aspect)
            let centerX = sticker.cx * size.width
            let centerY = sticker.cy * size.height
            cg.saveGState()
            cg.translateBy(x: centerX, y: centerY)
            cg.rotate(by: CGFloat(sticker.rotation) * CGFloat.pi / 180)
            image.draw(in: CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
            cg.restoreGState()
        }
    }

    // MARK: - 缩放富文本（字号、行距同比缩放）

    static func scaledAttributed(_ attr: NSAttributedString, by factor: CGFloat, lineSpacing: CGFloat) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: attr)
        let full = NSRange(location: 0, length: result.length)
        guard full.length > 0 else { return result }

        var loc = 0
        while loc < full.length {
            var eff = NSRange(location: 0, length: 0)
            let font = result.attribute(.font, at: loc, effectiveRange: &eff) as? UIFont
            if eff.length <= 0 { break }
            let weightValue = (result.attribute(kPosterWeight, at: loc, effectiveRange: nil) as? NSNumber)?.intValue ?? 1
            let oldSize = font?.pointSize ?? 20
            let newFont = UIFont.systemFont(ofSize: max(4, oldSize * factor),
                                            weight: PosterWeight.from(weightValue).uiWeight)
            let sub = NSIntersectionRange(eff, full)
            result.addAttribute(.font, value: newFont, range: sub)
            result.addAttribute(kPosterWeight, value: weightValue, range: sub)
            loc = eff.location + eff.length
        }

        var paraLoc = 0
        while paraLoc < full.length {
            var eff = NSRange(location: 0, length: 0)
            let para = result.attribute(.paragraphStyle, at: paraLoc, effectiveRange: &eff) as? NSParagraphStyle
            if eff.length <= 0 { break }
            let newPara = NSMutableParagraphStyle()
            if let original = para {
                newPara.setParagraphStyle(original)
            }
            newPara.lineSpacing = lineSpacing
            result.addAttribute(.paragraphStyle, value: newPara, range: NSIntersectionRange(eff, full))
            paraLoc = eff.location + eff.length
        }

        return result
    }
}
