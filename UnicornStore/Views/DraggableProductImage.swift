import SwiftUI

// MARK: - 可拖动图片视图
// 图片比框大时，用户可拖动挪动显示位置，偏移归一化 -1~1 保存到 Product

struct DraggableProductImage: View {
    let image: UIImage
    let frameWidth: CGFloat
    let frameHeight: CGFloat
    @Binding var offsetX: CGFloat
    @Binding var offsetY: CGFloat
    let draggable: Bool  // true=可拖动, false=只读展示
    
    init(image: UIImage, frameWidth: CGFloat, frameHeight: CGFloat,
         offsetX: Binding<CGFloat>, offsetY: Binding<CGFloat>,
         draggable: Bool = true) {
        self.image = image
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
        self._offsetX = offsetX
        self._offsetY = offsetY
        self.draggable = draggable
    }
    
    var body: some View {
        GeometryReader { _ in
            let imageSize = image.size
            let scale = max(frameWidth / imageSize.width, frameHeight / imageSize.height)
            let scaledW = imageSize.width * scale
            let scaledH = imageSize.height * scale
            let maxOX = max(0, (scaledW - frameWidth) / 2)
            let maxOY = max(0, (scaledH - frameHeight) / 2)
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: scaledW, height: scaledH)
                .offset(x: offsetX * maxOX, y: offsetY * maxOY)
                .gesture(draggable ? dragGesture(maxOX: maxOX, maxOY: maxOY) : nil)
                .clipped()
                .frame(width: frameWidth, height: frameHeight)
        }
        .frame(width: frameWidth, height: frameHeight)
        .cornerRadius(8)
    }
    
    private func dragGesture(maxOX: CGFloat, maxOY: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let dx = maxOX > 0 ? value.translation.width / maxOX : 0
                let dy = maxOY > 0 ? value.translation.height / maxOY : 0
                offsetX = max(-1, min(1, offsetX + dx))
                offsetY = max(-1, min(1, offsetY + dy))
            }
    }
}
