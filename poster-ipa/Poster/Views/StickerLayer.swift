import SwiftUI

// MARK: - 贴图层（点一下虚线框 / 拖动移动 / 双指缩放）

struct StickerLayer: View {
    @ObservedObject var store: PosterStore
    let canvas: CGSize
    @Binding var selectedId: UUID?
    /// 贴图工具打开时，所有贴图都显示淡虚线框，提示"这些可以拖"
    let showHint: Bool

    var body: some View {
        ZStack {
            ForEach(store.poster.stickers) { item in
                StickerNode(item: item,
                            canvas: canvas,
                            isSelected: selectedId == item.id,
                            showHint: showHint,
                            onSelect: {
                                selectedId = item.id
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
    let showHint: Bool
    var onSelect: () -> Void
    var onChange: (CGFloat, CGFloat, CGFloat, Double) -> Void

    @State private var dragBase: CGPoint? = nil
    @State private var pinchBase: CGFloat? = nil
    @State private var isMoving = false

    private var nodeWidth: CGFloat {
        return max(16, item.widthRatio * canvas.width)
    }

    private var nodeHeight: CGFloat {
        return max(16, nodeWidth / max(0.05, item.aspect))
    }

    private var lineWidth: CGFloat {
        return isSelected ? 2 : 1.5
    }

    private var borderColor: Color {
        if isSelected { return Color.blue }
        if showHint { return Color.blue.opacity(0.55) }
        return Color.clear
    }

    /// 选中 = 实线，提示 = 虚线
    private var dashArray: [CGFloat] {
        return isSelected ? [] : [6, 4]
    }

    var body: some View {
        contentView
            .frame(width: nodeWidth, height: nodeHeight)
            // 透明 PNG 也要能点中、拖得动
            .contentShape(Rectangle())
            .overlay(
                Rectangle()
                    .strokeBorder(borderColor,
                                  style: StrokeStyle(lineWidth: lineWidth, dash: dashArray))
            )
            .scaleEffect(isMoving ? 1.03 : 1.0)
            .shadow(color: Color.black.opacity(isMoving ? 0.28 : 0), radius: isMoving ? 10 : 0, x: 0, y: 3)
            .rotationEffect(.degrees(item.rotation))
            .position(x: item.cx * canvas.width, y: item.cy * canvas.height)
            .highPriorityGesture(dragGesture.simultaneously(with: pinchGesture))
    }

    @ViewBuilder private var contentView: some View {
        if let img = item.uiImage {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.25))
        }
    }

    private var dragGesture: some Gesture {
        // minimumDistance: 0 —— 手指一按下就抓住，不再被外层滚动抢走
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if dragBase == nil {
                    dragBase = CGPoint(x: item.cx, y: item.cy)
                    isMoving = true
                    onSelect()
                }
                guard let base = dragBase else { return }
                let nx = base.x + value.translation.width / max(1, canvas.width)
                let ny = base.y + value.translation.height / max(1, canvas.height)
                onChange(nx, ny, item.widthRatio, item.rotation)
            }
            .onEnded { _ in
                dragBase = nil
                isMoving = false
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
