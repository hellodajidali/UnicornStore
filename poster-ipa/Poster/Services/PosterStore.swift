import Foundation
import SwiftUI
import UIKit

// MARK: - 本地存储（草稿 + 模板）

final class PosterStore: ObservableObject {
    static let shared = PosterStore()

    @Published var poster: PosterData {
        didSet {
            scheduleSavePoster()
        }
    }

    @Published var templates: [Template] = [] {
        didSet {
            saveTemplates()
        }
    }

    private let posterFile = "poster_draft.json"
    private let templatesFile = "poster_templates.json"
    private var saveWork: DispatchWorkItem?

    private init() {
        if let loaded = PosterStore.load(PosterData.self, from: "poster_draft.json") {
            self.poster = loaded
        } else {
            self.poster = PosterData()
        }
        if let loaded = PosterStore.load([Template].self, from: "poster_templates.json") {
            self.templates = loaded
        } else {
            self.templates = []
        }
    }

    // MARK: - 磁盘

    private static func documentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    private static func url(_ name: String) -> URL {
        return documentsDirectory().appendingPathComponent(name)
    }

    static func load<T: Decodable>(_ type: T.Type, from name: String) -> T? {
        let file = url(name)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        do {
            let data = try Data(contentsOf: file)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("读取失败 \(name): \(error.localizedDescription)")
            return nil
        }
    }

    private func scheduleSavePoster() {
        saveWork?.cancel()
        let snapshot = poster
        let work = DispatchWorkItem {
            do {
                let data = try JSONEncoder().encode(snapshot)
                try data.write(to: PosterStore.url(self.posterFile))
            } catch {
                print("保存草稿失败: \(error.localizedDescription)")
            }
        }
        saveWork = work
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    private func saveTemplates() {
        let snapshot = templates
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try JSONEncoder().encode(snapshot)
                try data.write(to: PosterStore.url(self.templatesFile))
            } catch {
                print("保存模板失败: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 草稿修改（必须整体赋值 struct 才会触发刷新+存盘）

    func mutatePoster(_ block: (inout PosterData) -> Void) {
        var copy = poster
        block(&copy)
        poster = copy
    }

    func setText(_ attr: NSAttributedString) {
        mutatePoster { $0.setText(attr) }
    }

    // MARK: - 贴图

    func addSticker(image: UIImage) {
        guard let data = ImageTool.compressedData(image) else { return }
        var item = StickerItem(imageData: data)
        item.cx = 0.5
        item.cy = 0.5
        item.widthRatio = 0.35
        mutatePoster { $0.stickers.append(item) }
    }

    func updateSticker(_ id: UUID, _ block: (inout StickerItem) -> Void) {
        mutatePoster { p in
            guard let idx = p.stickers.firstIndex(where: { $0.id == id }) else { return }
            var item = p.stickers[idx]
            block(&item)
            item.cx = min(1.2, max(-0.2, item.cx))
            item.cy = min(1.2, max(-0.2, item.cy))
            item.widthRatio = min(1.6, max(0.05, item.widthRatio))
            p.stickers[idx] = item
        }
    }

    func deleteSticker(_ id: UUID) {
        mutatePoster { p in
            p.stickers.removeAll { $0.id == id }
        }
    }

    func bringSticker(_ id: UUID, toFront: Bool) {
        mutatePoster { p in
            guard let idx = p.stickers.firstIndex(where: { $0.id == id }) else { return }
            let item = p.stickers.remove(at: idx)
            if toFront {
                p.stickers.append(item)
            } else {
                p.stickers.insert(item, at: 0)
            }
        }
    }

    // MARK: - 模板

    func addTemplate(name: String, from data: PosterData) {
        var t = Template()
        t.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.name.isEmpty { t.name = "未命名模板" }
        t.data = data
        t.createdAt = Date()
        templates.insert(t, at: 0)
    }

    func updateTemplate(_ id: UUID, data: PosterData) {
        guard let idx = templates.firstIndex(where: { $0.id == id }) else { return }
        var list = templates
        list[idx].data = data
        list[idx].createdAt = Date()
        templates = list
    }

    func renameTemplate(_ id: UUID, name: String) {
        guard let idx = templates.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var list = templates
        list[idx].name = trimmed
        templates = list
    }

    func deleteTemplate(_ id: UUID) {
        templates.removeAll { $0.id == id }
    }

    // MARK: - 新建

    func newBlank() {
        var fresh = PosterData()
        fresh.bgHex = poster.bgHex
        fresh.bg2Hex = poster.bg2Hex
        fresh.gradient = poster.gradient
        fresh.ratioRaw = poster.ratioRaw
        fresh.defaultSize = poster.defaultSize
        fresh.defaultWeight = poster.defaultWeight
        fresh.textHex = poster.textHex
        fresh.lineSpacing = poster.lineSpacing
        poster = fresh
    }
}
