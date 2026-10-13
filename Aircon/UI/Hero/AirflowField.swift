import AirconKit
import SwiftUI

/// Air falling from the flap. Every streak is a pure function of time and its index, so a frame
/// allocates nothing and the timeline stops entirely when the unit is off or the panel is hidden.
struct AirflowField: View {
    struct Style: Equatable {
        var intensity: Double
        var droplets: Bool
        var swing: Bool

        init(state: ACState?) {
            intensity = state?.fan.intensity ?? 0.5
            droplets = state?.mode == .dry
            swing = state?.swing == true
        }
    }

    let style: Style
    let color: Color
    let running: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !running)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                context.blendMode = .plusLighter
                for index in 0..<Self.count(for: style) {
                    Self.drawParticle(index, at: time, style: style, color: color, in: &context, size: size)
                }
            }
        }
        .mask(LinearGradient(stops: [
            .init(color: .clear, location: 0),
            .init(color: .black, location: 0.12),
            .init(color: .black.opacity(0.7), location: 0.6),
            .init(color: .clear, location: 1),
        ], startPoint: .top, endPoint: .bottom))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private static func count(for style: Style) -> Int {
        Int(22 + 34 * style.intensity)
    }

    private static func drawParticle(
        _ index: Int, at time: TimeInterval, style: Style, color: Color,
        in context: inout GraphicsContext, size: CGSize
    ) {
        let lane = noise(index, 1) * 2 - 1
        let weight = noise(index, 2)
        let speed = 0.18 + 0.42 * style.intensity
        let progress = (time * speed * (0.75 + 0.5 * weight) + noise(index, 3)).truncatingRemainder(dividingBy: 1)

        // Air leaves the flap as a sheet as wide as the flap, falls mostly straight and fans out gently.
        // Swing sways the sheet a little from side to side, the way the louvre sweeps.
        let sway = style.swing ? sin(time * 0.8 + progress * 2) * 0.06 : 0
        let x = size.width * (0.5 + lane * (0.26 + 0.12 * progress) + sway * progress)
        let point = CGPoint(x: x, y: progress * size.height)
        let alpha = sin(progress * .pi) * (0.18 + 0.42 * weight)

        if style.droplets {
            let radius = 0.9 + 1.2 * weight
            let dot = Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
            context.fill(dot, with: .color(color.opacity(alpha)))
        } else {
            let length = 10 + 30 * style.intensity * (0.5 + weight)
            var streak = Path()
            streak.move(to: point)
            streak.addLine(to: CGPoint(x: point.x + lane * 0.12 * length + sway * length, y: point.y + length))
            let stroke = StrokeStyle(lineWidth: 0.8 + 0.8 * weight, lineCap: .round)
            context.stroke(streak, with: .color(color.opacity(alpha)), style: stroke)
        }
    }

    /// Stable pseudo-random 0…1 per particle.
    private static func noise(_ index: Int, _ salt: Int) -> Double {
        let value = sin(Double(index) * 12.9898 + Double(salt) * 78.233) * 43758.5453
        return value - value.rounded(.down)
    }
}
