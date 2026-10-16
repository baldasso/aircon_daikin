import AirconKit
import SwiftUI

struct ModeBar: View {
    let modes: [Mode]
    let selection: Mode
    let accent: Accent
    let onSelect: (Mode) -> Void

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 2) {
            ForEach(modes, id: \.self) { mode in
                ModeItem(mode: mode, isSelected: mode == selection, accent: accent, namespace: namespace) {
                    onSelect(mode)
                }
            }
        }
        .padding(4)
        .well(radius: Radius.row)
        .animation(Motion.snap, value: selection)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Mode")
    }
}

private struct ModeItem: View {
    let mode: Mode
    let isSelected: Bool
    let accent: Accent
    let namespace: Namespace.ID
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Counts selections, so only the mode being picked bounces, not the one it replaces.
    @State private var bounces = 0

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.item, style: .continuous)
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: mode.symbol)
                    .font(.system(size: 15, weight: .regular))
                    .symbolEffect(.bounce, value: bounces)
                Text(mode.title)
                    .font(.system(size: 10.5, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isSelected ? Ink.frost : Ink.mist)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background {
                if isSelected {
                    shape
                        .fill(accent.deep.opacity(0.32))
                        .overlay(shape.strokeBorder(accent.light.opacity(0.32)))
                        .shadow(color: accent.deep.opacity(0.35), radius: 10, y: 2)
                        .matchedGeometryEffect(id: "mode", in: namespace)
                }
            }
            .hoverHighlight(shape, isActive: !isSelected)
            .contentShape(shape)
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onChange(of: isSelected) { _, selected in
            if selected && !reduceMotion { bounces += 1 }
        }
    }
}
