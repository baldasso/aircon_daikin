import SwiftUI

/// Presses sink slightly, like a physical key.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(Motion.snap, value: configuration.isPressed)
    }
}

/// The recessed tray every control row sits in.
struct Well: ViewModifier {
    var radius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Ink.well))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Ink.hairline))
    }
}

extension View {
    func well(radius: CGFloat = 16) -> some View { modifier(Well(radius: radius)) }

    /// Rows rise into place one after another when the panel opens.
    func entrance(_ index: Int, shown: Bool) -> some View {
        modifier(Entrance(index: index, shown: shown))
    }
}

private struct Entrance: ViewModifier {
    let index: Int
    let shown: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 10)
            .animation(Motion.settle.delay(shown ? Double(index) * 0.04 : 0), value: shown)
    }
}

/// A glass text field for the settings forms.
private struct Field: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .foregroundStyle(Ink.frost)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .well(radius: 10)
    }
}

extension View {
    func fieldStyle() -> some View { modifier(Field()) }
}
