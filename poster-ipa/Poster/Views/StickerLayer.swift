import SwiftUI

// MARK: - 贴图层（拖拽移动 / 双指缩放）

struct StickerLayer: View {
    @ObservedObject var store: PosterStore
    let canvas: CGSize
    @Binding var selectedId: UUID?

    var body: some View {
        ZStack {
            ForEach(store.poster.stickers) { item in
                StickerNode(item: item,
                            canvas: canvas,
                            isSelected: selectedId == item.id,
                            onSelect: {
                                withAnimation(.easeOut(duration: 0.1)) {
                                    selectedId = item.id
                                }
                            },
                            onChange: { cx, cy, widthRatio, rotation in
                                store.updateSticker(item.id) { s in
                                    s.cx = cx
                                    s.cy = cy
                                    s.widthRatio = widthRatio
                                    s.rotation = rotation
                                }
                            })
            }
        }
    }
}

struct StickerNode: View {
    let item: StickerItem
    let canvas: CGSize
    let isSelected: Bool
    var onSelect: () -> Void
    var onChange: (CGFloat, CGFloat, CGFloat, Double) -> Void

    @State private var dragBase: CGPoint? = nil
    @State private var pinchBase: CGFloat? = nil

    private var nodeWidth: CGFloat {
        return max(16, item.widthRatio * canvas.width)
    }

    private var nodeHeight: CGFloat {
        return max(16, nodeWidth / max(0.05, item.aspect))
    }

    var body: some View {
        Group {
            if let img = item.uiImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: nodeWidth, height: nodeHeight)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: nodeWidth, height: nodeHeight)
            }
        }
        .overlay(
            Rectangle()
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
        )
        .rotationEffect(.degrees(item.rotation))
        .position(x: item.cx * canvas.width, y: item.cy * canvas.height)
        .onTapGesture {
            onSelect()
        }
        .gesture(dragGesture.simultaneously(with: pinchGesture))
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if dragBase == nil {
                    dragBase = CGPoint(x: item.cx, y: item.cy)
                    onSelect()
                }
                guard let base = dragBase else { return }
                let nx = base.x + value.translation.width / max(1, canvas.width)
                let ny = base.y + value.translation.height / max(1, canvas.height)
                onChange(nx, ny, item.widthRatio, item.rotation)
            }
            .onEnded { _ in
                dragBase = nil
            }
    }

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                if pinchBase == nil {
                    pinchBase = item.widthRatio
                    onSelect()
                }
                guard let base = pinchBase else { return }
                onChange(item.cx, item.cy, base * value, item.rotation)
            }
            .onEnded { _ in
                pinchBase = nil
            }
    }
}
