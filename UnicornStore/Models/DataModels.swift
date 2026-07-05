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
    
    // 整体主题色
    var themeColor: String  // hex颜色
    
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
            themeColor: "#9966CC"
        )
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
    var categoryId: UUID?
    var imageData: Data?
    var description: String
    
    var image: UIImage? {
        if let data = imageData {
            return UIImage(data: data)
        }
        return nil
    }
    
    init(id: UUID = UUID(), name: String, price: String, categoryId: UUID? = nil, imageData: Data? = nil, description: String = "") {
        self.id = id
        self.name = name
        self.price = price
        self.categoryId = categoryId
        self.imageData = imageData
        self.description = description
    }
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        lhs.id == rhs.id
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
