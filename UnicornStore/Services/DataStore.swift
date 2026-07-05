import Foundation
import UIKit

// MARK: - 本地数据存储服务

class DataStore: ObservableObject {
    static let shared = DataStore()
    
    @Published var storeData: StoreData {
        didSet {
            saveToDisk()
        }
    }
    
    private let fileName = "store_data.json"
    
    private init() {
        if let loaded = DataStore.loadFromDisk() {
            self.storeData = loaded
        } else {
            self.storeData = StoreData.defaultData()
        }
    }
    
    // MARK: - 磁盘读写
    
    private func documentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func fileURL() -> URL {
        return documentsDirectory().appendingPathComponent(fileName)
    }
    
    func saveToDisk() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(self.storeData)
                try data.write(to: self.fileURL())
            } catch {
                print("保存数据失败: \(error.localizedDescription)")
            }
        }
    }
    
    static func loadFromDisk() -> StoreData? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let documentsPath = paths.first else { return nil }
        let filePath = (documentsPath as NSString).appendingPathComponent("store_data.json")
        
        guard FileManager.default.fileExists(atPath: filePath) else { return nil }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let decoder = JSONDecoder()
            return try decoder.decode(StoreData.self, from: data)
        } catch {
            print("加载数据失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - 数据操作方法
    
    func saveImageToDocuments(_ image: UIImage, name: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileURL = documentsDirectory().appendingPathComponent("\(name).jpg")
        do {
            try data.write(to: fileURL)
            return "\(name).jpg"
        } catch {
            print("保存图片失败: \(error)")
            return nil
        }
    }
    
    func loadImageFromDocuments(_ fileName: String) -> UIImage? {
        let fileURL = documentsDirectory().appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    // MARK: - 商品操作
    
    func addProduct(_ product: Product) {
        storeData.products.append(product)
    }
    
    func updateProduct(_ product: Product) {
        if let index = storeData.products.firstIndex(where: { $0.id == product.id }) {
            storeData.products[index] = product
        }
    }
    
    func deleteProduct(_ product: Product) {
        storeData.products.removeAll { $0.id == product.id }
    }
    
    // MARK: - 分类操作
    
    func addCategory(_ name: String) {
        let category = Category(id: UUID(), name: name)
        storeData.categories.append(category)
    }
    
    func deleteCategory(_ category: Category) {
        if category.name == "全部分类" { return }
        // 使用 index 方式删除，确保只删除一个
        if let index = storeData.categories.firstIndex(where: { $0.id == category.id }) {
            storeData.categories.remove(at: index)
        }
    }
    
    func renameCategory(_ category: Category, newName: String) {
        if let index = storeData.categories.firstIndex(where: { $0.id == category.id }) {
            storeData.categories[index].name = newName
        }
    }
    
    func updateCategoryStyle(_ category: Category, fontSize: CGFloat, textColor: String) {
        if let index = storeData.categories.firstIndex(where: { $0.id == category.id }) {
            storeData.categories[index].fontSize = fontSize
            storeData.categories[index].textColor = textColor
        }
    }
    
    // MARK: - 导出/导入备份（分享 JSON 文件）
    
    func exportData() -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            return try encoder.encode(storeData)
        } catch {
            return nil
        }
    }
    
    func importData(_ data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            let imported = try decoder.decode(StoreData.self, from: data)
            self.storeData = imported
            return true
        } catch {
            return false
        }
    }
    
    /// 获取备份文件保存路径（供 UIActivityViewController 使用）
    func getBackupFileURL() -> URL? {
        let fileURL = documentsDirectory().appendingPathComponent("雾化胖东来备份_\(Date().timeIntervalSince1970).json")
        guard let data = exportData() else { return nil }
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
}
