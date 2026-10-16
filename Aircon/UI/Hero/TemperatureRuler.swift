import SwiftUI

/// A vertical tape of degrees that scrolls under a fixed marker. Animatable, so a setpoint change
/// glides the tape instead of jumping it.
struct TemperatureRuler: View, Animatable {
    var value: Double
    let pointsPerDegree: CGFloat
    let accent: Accent

    nonisolated var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let middle = size.height / 2
            let span = Double(middle / pointsPerDegree) + 1
            var tick = (value - span).rounded(.down)
            while tick <= value + span {
                drawTick(tick, middle: middle, in: &context, size: size)
                tick += 0.5
            }
            drawMarker(middle: middle, in: &context, size: size)
        }
        .accessibilityHidden(true)
    }

    private func drawTick(_ degree: Double, middle: CGFloat, in context: inout GraphicsContext, size: CGSize) {
        let y = middle + CGFloat(value - degree) * pointsPerDegree
        // Fades toward the ends, but never below what can still be read.
        let fade = 0.45 + 0.55 * max(0, 1 - abs(y - middle) / middle)
        let isWhole = degree.rounded() == degree
        let isLabelled = isWhole && Int(degree) % 2 == 0
        let length: CGFloat = isLabelled ? 14 : (isWhole ? 9 : 5)
        let right = size.width - 14

        var line = Path()
        line.move(to: CGPoint(x: right - length, y: y))
        line.addLine(to: CGPoint(x: right, y: y))
        context.stroke(line, with: .color(Ink.mist.opacity(0.6 * fade)), lineWidth: 1)

        if isLabelled {
            let label = Text("\(Int(degree))").font(Typeface.tick).foregroundStyle(Ink.mist.opacity(fade))
            context.draw(label, at: CGPoint(x: right - length - 5, y: y), anchor: .trailing)
        }
    }

    private func drawMarker(middle: CGFloat, in context: inout GraphicsContext, size: CGSize) {
        let right = size.width - 14
        var marker = Path()
        marker.move(to: CGPoint(x: right - 18, y: middle))
        marker.addLine(to: CGPoint(x: right + 2, y: middle))
        context.stroke(marker, with: .color(accent.light), style: StrokeStyle(lineWidth: 2, lineCap: .round))

        var notch = Path()
        notch.move(to: CGPoint(x: right + 10, y: middle - 4))
        notch.addLine(to: CGPoint(x: right + 5, y: middle))
        notch.addLine(to: CGPoint(x: right + 10, y: middle + 4))
        notch.closeSubpath()
        context.fill(notch, with: .color(accent.light))
    }
}
