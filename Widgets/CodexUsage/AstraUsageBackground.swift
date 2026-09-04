import SwiftUI

struct AstraUsageBackground: View {
    let isSelected: Bool
    let isHovering: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    private struct Star {
        let x: CGFloat
        let y: CGFloat
        let radius: CGFloat
        let phase: Double
        let speed: Double
        let isFourPoint: Bool
    }

    // Reuse the same constellation across redraws.
    private static let stars: [Star] = [
        Star(x: 0.08, y: 0.24, radius: 1.0, phase: 0.2, speed: 1.6, isFourPoint: true),
        Star(x: 0.19, y: 0.72, radius: 0.8, phase: 1.8, speed: 1.2, isFourPoint: false),
        Star(x: 0.31, y: 0.34, radius: 0.7, phase: 2.7, speed: 1.9, isFourPoint: false),
        Star(x: 0.43, y: 0.78, radius: 1.0, phase: 3.5, speed: 1.4, isFourPoint: true),
        Star(x: 0.54, y: 0.18, radius: 0.8, phase: 4.2, speed: 1.7, isFourPoint: false),
        Star(x: 0.65, y: 0.55, radius: 1.1, phase: 5.1, speed: 1.3, isFourPoint: true),
        Star(x: 0.77, y: 0.28, radius: 0.7, phase: 5.8, speed: 2.0, isFourPoint: false),
        Star(x: 0.90, y: 0.74, radius: 0.9, phase: 6.5, speed: 1.5, isFourPoint: true),
        Star(x: 0.13, y: 0.52, radius: 0.6, phase: 7.1, speed: 1.8, isFourPoint: false),
        Star(x: 0.36, y: 0.12, radius: 0.6, phase: 7.8, speed: 1.1, isFourPoint: false),
        Star(x: 0.60, y: 0.84, radius: 0.7, phase: 8.6, speed: 1.6, isFourPoint: false),
        Star(x: 0.84, y: 0.46, radius: 0.8, phase: 9.3, speed: 1.9, isFourPoint: false),
    ]

    var body: some View {
        TimelineView(
            .animation(minimumInterval: 1.0 / 18.0, paused: reduceMotion || !isVisible || !(isSelected || isHovering))
        ) { timeline in
            Canvas { context, size in
                let bounds = CGRect(origin: .zero, size: size)
                let shape = Path(roundedRect: bounds, cornerRadius: 11)

                context.fill(
                    shape,
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(red: 0.045, green: 0.010, blue: 0.11),
                            Color(red: 0.12, green: 0.020, blue: 0.25),
                            Color(red: 0.25, green: 0.055, blue: 0.44),
                        ]),
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: size.width, y: size.height)
                    )
                )
                context.clip(to: shape)

                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                for star in Self.stars {
                    let twinkle = 0.5 + (0.5 * sin(time * star.speed + star.phase))
                    let alpha = (isSelected ? 0.42 : 0.22) + (twinkle * (isSelected ? 0.52 : 0.28))
                    let center = CGPoint(x: size.width * star.x, y: size.height * star.y)
                    let glowRadius = star.radius * (isSelected ? 3.4 : 2.4)
                    let glowRect = CGRect(
                        x: center.x - glowRadius,
                        y: center.y - glowRadius,
                        width: glowRadius * 2,
                        height: glowRadius * 2
                    )

                    var glowContext = context
                    glowContext.addFilter(.blur(radius: max(1, star.radius * 1.8)))
                    glowContext.fill(
                        Path(ellipseIn: glowRect),
                        with: .color(Color(red: 0.72, green: 0.42, blue: 1.00).opacity(alpha * 0.72))
                    )

                    let starPath = star.isFourPoint
                        ? fourPointPath(center: center, radius: star.radius * (1.0 + (twinkle * 0.35)))
                        : Path(ellipseIn: CGRect(
                            x: center.x - star.radius,
                            y: center.y - star.radius,
                            width: star.radius * 2,
                            height: star.radius * 2
                        ))
                    context.fill(starPath, with: .color(.white.opacity(alpha)))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func fourPointPath(center: CGPoint, radius: CGFloat) -> Path {
        let diagonal = radius * 0.42
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - radius * 2.2))
        path.addLine(to: CGPoint(x: center.x + diagonal, y: center.y - diagonal))
        path.addLine(to: CGPoint(x: center.x + radius * 2.2, y: center.y))
        path.addLine(to: CGPoint(x: center.x + diagonal, y: center.y + diagonal))
        path.addLine(to: CGPoint(x: center.x, y: center.y + radius * 2.2))
        path.addLine(to: CGPoint(x: center.x - diagonal, y: center.y + diagonal))
        path.addLine(to: CGPoint(x: center.x - radius * 2.2, y: center.y))
        path.addLine(to: CGPoint(x: center.x - diagonal, y: center.y - diagonal))
        path.closeSubpath()
        return path
    }
}
