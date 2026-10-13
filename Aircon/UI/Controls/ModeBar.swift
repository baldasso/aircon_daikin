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
                item(mode, isSelected: mode == selection)
            }
        }
        .padding(4)
        .well(radius: 18)
        .animation(Motion.snap, value: selection)
    }

    private func item(_ mode: Mode, isSelected: Bool) -> some View {
        Button {
            onSelect(mode)
        } label: {
            VStack(spacing: 5) {
                Image(systemName: mode.symbol)
                    .font(.system(size: 15, weight: .regular))
                    .symbolEffect(.bounce, value: isSelected)
                Text(mode.title)
                    .font(.system(size: 10.5, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isSelected ? Ink.frost : Ink.mist)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accent.deep.opacity(0.32))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(accent.light.opacity(0.32)))
                        .shadow(color: accent.deep.opacity(0.35), radius: 10, y: 2)
                        .matchedGeometryEffect(id: "mode", in: namespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
