import Foundation
import UIKit

// MARK: - 数据模型

struct StoreData: Codable {
    var topBanner: Banner
    var announcement: Announcement
    var categories: [Category]
    var products: [Product]
    var gridColumns: Int
    var showPrice: Bool
    
    static func defaultData() -> StoreData {
        let allCategory = Category(id: UUID(), name: "全部分类")
        let cat1 = Category(id: UUID(), name: "热门推荐")
        let cat2 = Category(id: UUID(), name: "新品上架")
        
        return StoreData(
            topBanner: Banner(text: "欢迎来到独角商店", imageData: nil),
            announcement: Announcement(text: "📢 本店商品均为正品，支持退换货服务"),
            categories: [allCategory, cat1, cat2],
            products: [
                Product(name: "示例商品1", price: "¥99.00", categoryId: cat1.id, imageData: nil, description: "这是示例商品1的描述"),
                Product(name: "示例商品2", price: "¥199.00", categoryId: cat1.id, imageData: nil, description: "这是示例商品2的描述"),
                Product(name: "示例商品3", price: "¥299.00", categoryId: cat2.id, imageData: nil, description: "这是示例商品3的描述"),
            ],
            gridColumns: 3,
            showPrice: true
        )
    }
}

struct Banner: Codable {
    var text: String
    var imageData: Data?
    
    var image: UIImage? {
        if let data = imageData {
            return UIImage(data: data)
        }
        return nil
    }
}

struct Announcement: Codable {
    var text: String
}

struct Category: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    
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
