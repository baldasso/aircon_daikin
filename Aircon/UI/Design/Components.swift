import SwiftUI

/// Presses sink slightly, like a physical key.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .focusRing(RoundedRectangle(cornerRadius: Radius.item, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(Motion.snap, value: configuration.isPressed)
    }
}

/// Where keyboard focus is, for Full Keyboard Access: custom controls draw no ring of their own.
private struct FocusRing<S: InsettableShape>: ViewModifier {
    let shape: S
    @Environment(\.isFocused) private var isFocused

    func body(content: Content) -> some View {
        content.overlay {
            if isFocused {
                shape.inset(by: -2).strokeBorder(Color.accentColor.opacity(0.85), lineWidth: 2)
            }
        }
    }
}

/// The recessed tray every control row sits in.
struct Well: ViewModifier {
    var radius: CGFloat = Radius.row
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Ink.well(contrast)))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Ink.hairline(contrast)))
    }
}

/// A faint lift under the pointer, so custom controls answer the mouse the way native ones do.
struct HoverHighlight<S: Shape>: ViewModifier {
    let shape: S
    var isActive = true
    @State private var hovering = false

    func body(content: Content) -> some View {
        content
            .background(shape.fill(Color.white.opacity(hovering && isActive ? 0.07 : 0)))
            .onHover { hovering = $0 }
            .animation(Motion.snap, value: hovering)
    }
}

extension View {
    func well(radius: CGFloat = Radius.row) -> some View { modifier(Well(radius: radius)) }

    func focusRing(_ shape: some InsettableShape) -> some View { modifier(FocusRing(shape: shape)) }

    func hoverHighlight(_ shape: some Shape, isActive: Bool = true) -> some View {
        modifier(HoverHighlight(shape: shape, isActive: isActive))
    }

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
            .well(radius: Radius.item)
    }
}

extension View {
    func fieldStyle() -> some View { modifier(Field()) }
}
