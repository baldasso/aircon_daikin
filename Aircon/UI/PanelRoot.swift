import AirconKit
import SwiftUI

struct PanelRoot: View {
    let home: Home
    let library: DeviceLibrary
    let panel: PanelState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            switch panel.screen {
            case .controls:
                ControlsScreen(home: home, library: library) { panel.screen = .settings }
                    .transition(slide(from: .leading))
            case .settings:
                SettingsScreen(library: library, panel: panel) { panel.screen = .controls }
                    .transition(slide(from: .trailing))
            }
        }
        .animation(Motion.settle, value: panel.screen)
        .frame(width: PanelController.size.width, height: PanelController.size.height, alignment: .top)
        .background(PanelBackdrop(accent: Accent.of(home.selectedRoom?.state)))
        .clipShape(RoundedRectangle(cornerRadius: Radius.panel, style: .continuous))
        .environment(\.panelIsVisible, panel.isVisible)
        .environment(\.colorScheme, .dark)
    }

    /// Settings slide in beside the controls; with Reduce Motion they just cross-fade.
    private func slide(from edge: Edge) -> AnyTransition {
        reduceMotion ? .opacity : .move(edge: edge).combined(with: .opacity)
    }
}

/// Dark glass with a glow from above in the unit's color, like light through a frosted window.
private struct PanelBackdrop: View {
    let accent: Accent

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.panel, style: .continuous)
        ZStack {
            shape.fill(reduceTransparency ? Ink.solid : Ink.night.opacity(0.62))
            RadialGradient(colors: [accent.deep.opacity(0.42), .clear], center: .top, startRadius: 0, endRadius: 360)
            RadialGradient(colors: [accent.light.opacity(0.10), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 260)
        }
        .glassEffect(.regular, in: shape)
        .overlay(shape.strokeBorder(contrast == .increased ? Ink.hairline(contrast) : .white.opacity(0.10)))
        .animation(Motion.tint, value: accent)
    }
}
