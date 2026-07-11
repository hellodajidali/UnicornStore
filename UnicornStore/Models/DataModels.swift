import Foundation
import UIKit
import SwiftUI

// MARK: - 数据模型

struct StoreData: Codable {
    // 商店名称相关
    var storeName: String
    var storeNameFontSize: CGFloat
    var storeNameColor: String  // hex颜色
    
    // 公告
    var announcement: Announcement
    
    // 分类
    var categories: [Category]
    
    // 商品
    var products: [Product]
    
    // 布局
    var gridColumns: Int
    var showPrice: Bool
    var showTextOnly: Bool  // true=纯文字显示模式（只显示商品名和价格）
    
    // 整体主题色
    var themeColor: String  // hex颜色
    
    // 背景颜色（独立于主题色）
    var announcementBgColor: String  // hex颜色，默认浅灰
    var storeNameBgColor: String     // hex颜色，默认白色
    
    // 报价单设置
    var quoteSingleColumn: Bool  // true=单排显示，false=双排
    var quoteFooter: String      // 底部文字
    
    // 活动设置
    var showPromotion: Bool  // true=显示活动标签
    
    static func defaultData() -> StoreData {
        let allCategory = Category(id: UUID(), name: "全部")
        let cat1 = Category(id: UUID(), name: "热门推荐")
        let cat2 = Category(id: UUID(), name: "新品上架")
        
        return StoreData(
            storeName: "雾化胖东来",
            storeNameFontSize: 24,
            storeNameColor: "#9966CC",
            announcement: Announcement(text: "本店商品均为正品，支持退换货服务", fontSize: 14, textColor: "#663399"),
            categories: [allCategory, cat1, cat2],
            products: [
                Product(name: "示例商品1", price: "¥99.00", categoryId: cat1.id, imageData: nil, description: "这是示例商品1的描述"),
                Product(name: "示例商品2", price: "¥199.00", categoryId: cat1.id, imageData: nil, description: "这是示例商品2的描述"),
                Product(name: "示例商品3", price: "¥299.00", categoryId: cat2.id, imageData: nil, description: "这是示例商品3的描述"),
            ],
            gridColumns: 3,
            showPrice: true,
            showTextOnly: false,
            themeColor: "#9966CC",
            announcementBgColor: "#F0F0F0",
            storeNameBgColor: "#FFFFFF",
            quoteSingleColumn: false,
            quoteFooter: "谢谢惠顾！欢迎下次光临",
            showPromotion: true
        )
    }
    
    // 自定义 Codable 兼容旧数据（新加的字段如果没有就使用默认值）
    enum CodingKeys: String, CodingKey {
        case storeName, storeNameFontSize, storeNameColor, announcement
        case categories, products, gridColumns, showPrice, showTextOnly, themeColor
        case announcementBgColor, storeNameBgColor, quoteSingleColumn, quoteFooter, showPromotion
    }
    
    init(storeName: String, storeNameFontSize: CGFloat, storeNameColor: String,
         announcement: Announcement, categories: [Category], products: [Product],
         gridColumns: Int, showPrice: Bool, showTextOnly: Bool = false, themeColor: String,
         announcementBgColor: String = "#F0F0F0", storeNameBgColor: String = "#FFFFFF",
         quoteSingleColumn: Bool = false, quoteFooter: String = "谢谢惠顾！欢迎下次光临",
         showPromotion: Bool = true) {
        self.storeName = storeName
        self.storeNameFontSize = storeNameFontSize
        self.storeNameColor = storeNameColor
        self.announcement = announcement
        self.categories = categories
        self.products = products
        self.gridColumns = gridColumns
        self.showPrice = showPrice
        self.showTextOnly = showTextOnly
        self.themeColor = themeColor
        self.announcementBgColor = announcementBgColor
        self.storeNameBgColor = storeNameBgColor
        self.quoteSingleColumn = quoteSingleColumn
        self.quoteFooter = quoteFooter
        self.showPromotion = showPromotion
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        storeName = try c.decode(String.self, forKey: .storeName)
        storeNameFontSize = try c.decode(CGFloat.self, forKey: .storeNameFontSize)
        storeNameColor = try c.decode(String.self, forKey: .storeNameColor)
        announcement = try c.decode(Announcement.self, forKey: .announcement)
        categories = try c.decode([Category].self, forKey: .categories)
        products = try c.decode([Product].self, forKey: .products)
        gridColumns = try c.decode(Int.self, forKey: .gridColumns)
        showPrice = try c.decode(Bool.self, forKey: .showPrice)
        showTextOnly = try c.decodeIfPresent(Bool.self, forKey: .showTextOnly) ?? false
        themeColor = try c.decode(String.self, forKey: .themeColor)
        announcementBgColor = try c.decodeIfPresent(String.self, forKey: .announcementBgColor) ?? "#F0F0F0"
        storeNameBgColor = try c.decodeIfPresent(String.self, forKey: .storeNameBgColor) ?? "#FFFFFF"
        quoteSingleColumn = try c.decodeIfPresent(Bool.self, forKey: .quoteSingleColumn) ?? false
        quoteFooter = try c.decodeIfPresent(String.self, forKey: .quoteFooter) ?? "谢谢惠顾！欢迎下次光临"
        showPromotion = try c.decodeIfPresent(Bool.self, forKey: .showPromotion) ?? true
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(storeName, forKey: .storeName)
        try c.encode(storeNameFontSize, forKey: .storeNameFontSize)
        try c.encode(storeNameColor, forKey: .storeNameColor)
        try c.encode(announcement, forKey: .announcement)
        try c.encode(categories, forKey: .categories)
        try c.encode(products, forKey: .products)
        try c.encode(gridColumns, forKey: .gridColumns)
        try c.encode(showPrice, forKey: .showPrice)
        try c.encode(showTextOnly, forKey: .showTextOnly)
        try c.encode(themeColor, forKey: .themeColor)
        try c.encode(announcementBgColor, forKey: .announcementBgColor)
        try c.encode(storeNameBgColor, forKey: .storeNameBgColor)
        try c.encode(quoteSingleColumn, forKey: .quoteSingleColumn)
        try c.encode(quoteFooter, forKey: .quoteFooter)
        try c.encode(showPromotion, forKey: .showPromotion)
    }
}

struct Announcement: Codable {
    var text: String
    var fontSize: CGFloat
    var textColor: String  // hex颜色
    
    init(text: String, fontSize: CGFloat = 14, textColor: String = "#663399") {
        self.text = text
        self.fontSize = fontSize
        self.textColor = textColor
    }
}

struct Category: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var fontSize: CGFloat
    var textColor: String  // hex颜色
    
    init(id: UUID = UUID(), name: String, fontSize: CGFloat = 15, textColor: String = "#663399") {
        self.id = id
        self.name = name
        self.fontSize = fontSize
        self.textColor = textColor
    }
    
    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }
}

struct Product: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var price: String
    var originalPrice: String  // 原价（用于显示涨跌），空字符串表示未设置
    var categoryId: UUID?
    var imageData: Data?
    var description: String
    var isActive: Bool  // true=上架展示, false=下架隐藏
    var imageOffsetX: CGFloat  // 图片水平偏移（归一化 -1~1）
    var imageOffsetY: CGFloat  // 图片垂直偏移（归一化 -1~1）
    var promotion: String  // 活动信息，非空时显示红色"活动"标签
    
    var image: UIImage? {
        if let data = imageData {
            return UIImage(data: data)
        }
        return nil
    }
    
    /// 从价格字符串中提取数字（如 "¥99.00" → 99.0）
    private var numericPrice: Double? {
        let s = price.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(s)
    }
    
    private var numericOriginalPrice: Double? {
        let s = originalPrice.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(s)
    }
    
    /// 是否有有效原价且和现价不同
    var hasValidOriginalPrice: Bool {
        !originalPrice.isEmpty && originalPrice != price &&
        numericPrice != nil && numericOriginalPrice != nil
    }
    
    /// 价格变化百分比字符串（如 "-15%" 或 "+10%"）
    var priceChangePercent: String? {
        guard hasValidOriginalPrice, let current = numericPrice, let orig = numericOriginalPrice, orig != 0 else { return nil }
        let diff = ((current - orig) / orig * 100).rounded()
        if diff == 0 { return nil }
        return diff > 0 ? "+\(Int(diff))%" : "\(Int(diff))%"
    }
    
    /// 价格变化方向：true=降价, false=涨价
    var isPriceDown: Bool {
        guard hasValidOriginalPrice, let current = numericPrice, let orig = numericOriginalPrice else { return false }
        return current < orig
    }
    
    init(id: UUID = UUID(), name: String, price: String, originalPrice: String = "", categoryId: UUID? = nil, imageData: Data? = nil, description: String = "", isActive: Bool = true, imageOffsetX: CGFloat = 0, imageOffsetY: CGFloat = 0, promotion: String = "") {
        self.id = id
        self.name = name
        self.price = price
        self.originalPrice = originalPrice
        self.categoryId = categoryId
        self.imageData = imageData
        self.description = description
        self.isActive = isActive
        self.imageOffsetX = imageOffsetX
        self.imageOffsetY = imageOffsetY
        self.promotion = promotion
    }
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        lhs.id == rhs.id
    }
    
    // 自定义 Codable 兼容旧数据
    enum CodingKeys: String, CodingKey {
        case id, name, price, originalPrice, categoryId, imageData, description, isActive, imageOffsetX, imageOffsetY, promotion
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        price = try c.decode(String.self, forKey: .price)
        originalPrice = try c.decodeIfPresent(String.self, forKey: .originalPrice) ?? ""
        categoryId = try c.decodeIfPresent(UUID.self, forKey: .categoryId)
        imageData = try c.decodeIfPresent(Data.self, forKey: .imageData)
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        isActive = try c.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        imageOffsetX = try c.decodeIfPresent(CGFloat.self, forKey: .imageOffsetX) ?? 0
        imageOffsetY = try c.decodeIfPresent(CGFloat.self, forKey: .imageOffsetY) ?? 0
        promotion = try c.decodeIfPresent(String.self, forKey: .promotion) ?? ""
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(price, forKey: .price)
        try c.encode(originalPrice, forKey: .originalPrice)
        try c.encodeIfPresent(categoryId, forKey: .categoryId)
        try c.encodeIfPresent(imageData, forKey: .imageData)
        try c.encode(description, forKey: .description)
        try c.encode(isActive, forKey: .isActive)
        try c.encode(imageOffsetX, forKey: .imageOffsetX)
        try c.encode(imageOffsetY, forKey: .imageOffsetY)
        try c.encode(promotion, forKey: .promotion)
    }
}

// MARK: - 颜色工具扩展

extension String {
    /// 将 hex 颜色字符串转为 Color（支持 #RGB 和 #RRGGBB）
    func toColor() -> Color {
        let hex = trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b: UInt64
        switch hex.count {
        case 3:
            (r, g, b) = ((int >> 8) * 17, ((int >> 4) & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (r, g, b) = (int >> 16, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0x99, 0x66, 0xCC) // 默认紫色
        }
        
        return Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
    
    /// 转为 UIColor
    func toUIColor() -> UIColor {
        let hex = trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b: CGFloat
        switch hex.count {
        case 3:
            (r, g, b) = (CGFloat((int >> 8) * 17) / 255, CGFloat(((int >> 4) & 0xF) * 17) / 255, CGFloat((int & 0xF) * 17) / 255)
        case 6:
            (r, g, b) = (CGFloat((int >> 16) & 0xFF) / 255, CGFloat((int >> 8) & 0xFF) / 255, CGFloat(int & 0xFF) / 255)
        default:
            (r, g, b) = (0x99/255, 0x66/255, 0xCC/255)
        }
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
}

extension Color {
    /// 转成 hex 字符串
    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
