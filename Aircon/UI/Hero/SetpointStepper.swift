import AirconKit
import SwiftUI

/// One click, one degree. Holding a button keeps stepping, so a long way is still one gesture.
struct SetpointStepper: View {
    let setpoint: Double
    let accent: Accent
    let step: (Double) -> Void

    var body: some View {
        VStack(spacing: 0) {
            StepButton(symbol: "chevron.up", label: "Warmer", accent: accent, enabled: setpoint < ACState.setpointRange.upperBound) {
                step(1)
            }
            Rectangle()
                .fill(Ink.hairline)
                .frame(width: 18, height: 1)
            StepButton(symbol: "chevron.down", label: "Cooler", accent: accent, enabled: setpoint > ACState.setpointRange.lowerBound) {
                step(-1)
            }
        }
        .background(Capsule().fill(.white.opacity(0.06)))
        .overlay(Capsule().strokeBorder(Ink.hairline))
    }
}

private struct StepButton: View {
    let symbol: String
    let label: LocalizedStringKey
    let accent: Accent
    let enabled: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(hovering && enabled ? accent.light : Ink.frost.opacity(enabled ? 0.85 : 0.25))
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .buttonRepeatBehavior(.enabled)
        .disabled(!enabled)
        .onHover { hovering = $0 }
        .animation(Motion.snap, value: hovering)
        .help(Text(label))
    }
}
