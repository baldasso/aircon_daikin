import AirconKit
import SwiftUI

struct PanelRoot: View {
    let home: Home
    let library: DeviceLibrary
    let panel: PanelState

    var body: some View {
        ZStack {
            switch panel.screen {
            case .controls:
                ControlsScreen(home: home, library: library) { panel.screen = .settings }
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)).combined(with: .opacity))
            case .settings:
                SettingsScreen(library: library, panel: panel) { panel.screen = .controls }
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)).combined(with: .opacity))
            }
        }
        .animation(Motion.settle, value: panel.screen)
        .frame(width: PanelController.size.width, height: PanelController.size.height, alignment: .top)
        .background(PanelBackdrop(accent: Accent.of(home.selectedRoom?.state)))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .environment(\.panelIsVisible, panel.isVisible)
        .environment(\.colorScheme, .dark)
    }
}

/// Dark glass with a glow from above in the unit's color, like light through a frosted window.
private struct PanelBackdrop: View {
    let accent: Accent

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
        ZStack {
            shape.fill(Ink.night.opacity(0.62))
            RadialGradient(colors: [accent.deep.opacity(0.42), .clear], center: .top, startRadius: 0, endRadius: 360)
            RadialGradient(colors: [accent.light.opacity(0.10), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 260)
        }
        .glassEffect(.regular, in: shape)
        .overlay(shape.strokeBorder(Color.white.opacity(0.10)))
        .animation(Motion.tint, value: accent)
    }
}
