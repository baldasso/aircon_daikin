import AirconKit
import SwiftUI

/// Air falling from the flap. Every streak is a pure function of time and its index, so a frame
/// allocates nothing and the timeline stops entirely when the unit is off or the panel is hidden.
/// The air tells the mode: a cold stream, droplets when drying, open gusts for fan only, a warm shimmer for heat.
struct AirflowField: View {
    enum Kind: Equatable {
        case stream, droplets, gusts, shimmer

        init(_ mode: Mode?) {
            switch mode {
            case .dry: self = .droplets
            case .fan: self = .gusts
            case .heat: self = .shimmer
            case .cool, .auto, nil: self = .stream
            }
        }
    }

    struct Style: Equatable {
        var intensity: Double
        var kind: Kind
        var swing: Bool

        init(intensity: Double, kind: Kind, swing: Bool) {
            self.intensity = intensity
            self.kind = kind
            self.swing = swing
        }

        init(state: ACState?) {
            intensity = state?.fan.intensity ?? 0.5
            kind = Kind(state?.mode)
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
        let pace = style.kind == .shimmer ? 0.7 : 1
        let speed = (0.18 + 0.42 * style.intensity) * pace
        let progress = (time * speed * (0.75 + 0.5 * weight) + noise(index, 3)).truncatingRemainder(dividingBy: 1)

        // Air leaves the flap as a sheet as wide as the flap, falls mostly straight and fans out gently.
        // Swing sways the sheet a little from side to side, the way the louvre sweeps.
        let sway = style.swing ? sin(time * 0.8 + progress * 2) * 0.06 : 0
        let spread = style.kind == .gusts ? 0.26 * progress : 0.12 * progress
        let x = size.width * (0.5 + lane * (0.26 + spread) + sway * progress)
        let point = CGPoint(x: x, y: progress * size.height)
        var alpha = sin(progress * .pi) * (0.18 + 0.42 * weight) * rulerClearance(x, width: size.width)
        if style.kind == .gusts {
            // Puffs: each side of the sheet swells and eases on its own beat.
            alpha *= 0.55 + 0.45 * sin(time * 1.6 + lane * 2.5)
        }
        let shading = GraphicsContext.Shading.color(color.opacity(alpha))

        switch style.kind {
        case .droplets:
            let radius = 0.9 + 1.2 * weight
            context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)), with: shading)
        case .stream, .gusts:
            let length = 10 + 30 * style.intensity * (0.5 + weight)
            let slant = style.kind == .gusts ? 0.45 : 0.12
            var streak = Path()
            streak.move(to: point)
            streak.addLine(to: CGPoint(x: point.x + lane * slant * length + sway * length, y: point.y + length))
            context.stroke(streak, with: shading, style: StrokeStyle(lineWidth: 0.8 + 0.8 * weight, lineCap: .round))
        case .shimmer:
            // Warm air wavers: a short S-curve whose bend drifts with time.
            let length = 12 + 18 * style.intensity * (0.5 + weight)
            let bend = sin(time * 2.2 + Double(index)) * 4
            var wisp = Path()
            wisp.move(to: point)
            wisp.addQuadCurve(
                to: CGPoint(x: point.x + lane * 0.1 * length, y: point.y + length),
                control: CGPoint(x: point.x + bend, y: point.y + length / 2)
            )
            context.stroke(wisp, with: shading, style: StrokeStyle(lineWidth: 1 + weight, lineCap: .round))
        }
    }

    /// Fades the air out before it reaches the ruler on the right, so the ticks stay legible.
    /// Done per particle rather than with a mask, which would cost an offscreen pass every frame.
    private static func rulerClearance(_ x: Double, width: Double) -> Double {
        let edge = width - 44
        return min(1, max(0, (edge - x) / 40))
    }

    /// Stable pseudo-random 0…1 per particle.
    private static func noise(_ index: Int, _ salt: Int) -> Double {
        let value = sin(Double(index) * 12.9898 + Double(salt) * 78.233) * 43758.5453
        return value - value.rounded(.down)
    }
}
