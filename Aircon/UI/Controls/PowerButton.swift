import SwiftUI

/// Turning on is the main thing you come here to do, so it gets the tinted glass; turning off stays quiet.
struct PowerButton: View {
    let isOn: Bool
    let accent: Accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(isOn ? "Turn off" : "Turn on", systemImage: "power")
        }
        .buttonStyle(isOn ? AnyButtonStyle(SecondaryButtonStyle()) : AnyButtonStyle(PrimaryButtonStyle(accent: accent)))
        .animation(Motion.settle, value: isOn)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let accent: Accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Ink.frost)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Capsule())
            .glassEffect(.regular.tint(accent.deep.opacity(0.4)).interactive(), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.snap, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var tint = Ink.frost

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Capsule().fill(Color.white.opacity(configuration.isPressed ? 0.12 : 0.07)))
            .overlay(Capsule().strokeBorder(Ink.hairline))
            .hoverHighlight(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.snap, value: configuration.isPressed)
    }
}

/// Lets one button switch styles with its state.
struct AnyButtonStyle: ButtonStyle {
    private let make: (Configuration) -> AnyView

    init(_ style: some ButtonStyle) {
        make = { AnyView(style.makeBody(configuration: $0)) }
    }

    func makeBody(configuration: Configuration) -> some View {
        make(configuration)
    }
}
