import SwiftUI

struct CollimationOverlay: View {
    let circleRadii: [CGFloat]
    let lineWidth: CGFloat
    let overlayOpacity: Double
    let overlayColor: Color
    @Binding var centerOffset: CGSize

    @State private var dragStartOffset: CGSize?

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(
                x: geometry.size.width / 2 + centerOffset.width,
                y: geometry.size.height / 2 + centerOffset.height
            )
            let crosshairRadius = (circleRadii.max() ?? 120) + 32

            Canvas { context, _ in
                var overlayPath = Path()
                overlayPath.move(to: CGPoint(x: center.x - crosshairRadius, y: center.y))
                overlayPath.addLine(to: CGPoint(x: center.x + crosshairRadius, y: center.y))
                overlayPath.move(to: CGPoint(x: center.x, y: center.y - crosshairRadius))
                overlayPath.addLine(to: CGPoint(x: center.x, y: center.y + crosshairRadius))

                for radius in circleRadii.sorted() {
                    overlayPath.addEllipse(
                        in: CGRect(
                            x: center.x - radius,
                            y: center.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        )
                    )
                }

                context.stroke(
                    overlayPath,
                    with: .color(overlayColor.opacity(overlayOpacity)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )

                let centerMarker = Path(
                    ellipseIn: CGRect(x: center.x - 7, y: center.y - 7, width: 14, height: 14)
                )
                context.fill(centerMarker, with: .color(overlayColor.opacity(min(1, overlayOpacity + 0.15))))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if dragStartOffset == nil {
                            dragStartOffset = centerOffset
                        }

                        let startOffset = dragStartOffset ?? .zero
                        centerOffset = CGSize(
                            width: startOffset.width + value.translation.width,
                            height: startOffset.height + value.translation.height
                        )
                    }
                    .onEnded { _ in
                        dragStartOffset = nil
                    }
            )
        }
        .ignoresSafeArea()
    }
}
