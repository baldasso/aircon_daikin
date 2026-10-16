import AirconKit
import SwiftUI

/// The three extras the unit offers: swing, eco and powerful.
struct FeatureRow: View {
    let state: ACState
    let accent: Accent
    let room: Room

    var body: some View {
        HStack(spacing: 8) {
            FeatureToggle(title: "Swing", symbols: ("arrow.up.and.down", "arrow.up.and.down"), isOn: state.swing, accent: accent) {
                room.change { $0.swing = !state.swing }
            }
            FeatureToggle(title: "Eco", symbols: ("leaf", "leaf.fill"), isOn: state.eco, accent: accent) {
                room.change { $0.eco = !state.eco }
            }
            FeatureToggle(title: "Powerful", symbols: ("bolt", "bolt.fill"), isOn: state.powerful, accent: accent) {
                room.change { $0.powerful = !state.powerful }
            }
        }
    }
}

private struct FeatureToggle: View {
    let title: LocalizedStringKey
    /// Off and on variants; not every symbol has a filled form.
    let symbols: (off: String, on: String)
    let isOn: Bool
    let accent: Accent
    let action: () -> Void

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isOn ? symbols.on : symbols.off)
                    .font(.system(size: 11.5, weight: .medium))
                    .contentTransition(.symbolEffect(.replace))
                Text(title)
                    .font(.system(size: 11.5, weight: .medium))
            }
            .foregroundStyle(isOn ? accent.light : Ink.mist)
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(Capsule().fill(isOn ? accent.deep.opacity(0.24) : Ink.well(contrast)))
            .overlay(Capsule().strokeBorder(isOn ? accent.light.opacity(0.28) : Ink.hairline(contrast)))
            .hoverHighlight(Capsule(), isActive: !isOn)
            .animation(Motion.snap, value: isOn)
        }
        .buttonStyle(PressableStyle())
        .accessibilityValue(isOn ? Text("On") : Text("Off", comment: "A feature that is switched off"))
        .accessibilityAddTraits(.isToggle)
    }
}
