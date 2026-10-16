import AirconKit
import SwiftUI

/// Five bars for fixed speeds, rising with the airflow, plus Auto and Quiet.
/// The row says "Speed", not "Fan": Fan is already one of the modes right above it.
struct FanControl: View {
    let speed: FanSpeed
    let accent: Accent
    let onSelect: (FanSpeed) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(String(localized: "fan.row.title", defaultValue: "Speed", comment: "Label of the fan speed row"))
                .font(Typeface.label)
                .foregroundStyle(Ink.mist)
                .lineLimit(1)
                .fixedSize()
                .accessibilityHidden(true)

            Spacer(minLength: 0)

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(FanSpeed.levels.enumerated()), id: \.offset) { index, level in
                    bar(level, height: 8 + CGFloat(index) * 4, isLit: (speed.level ?? 0) > index)
                }
            }
            .frame(height: 28, alignment: .bottom)
            .padding(.trailing, 4)

            pill(.auto, spoken: "Automatic fan speed") {
                Text("Auto").padding(.horizontal, 9)
            }
            pill(.quiet, spoken: "Quiet fan speed") {
                Image(systemName: "moon.fill").frame(width: 28)
            }
            .help(Text("Quiet fan speed"))
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .well()
        .animation(Motion.snap, value: speed)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(String(localized: "fan.row.title", defaultValue: "Speed", comment: "Label of the fan speed row")))
    }

    private func bar(_ level: FanSpeed, height: CGFloat, isLit: Bool) -> some View {
        Button {
            onSelect(level)
        } label: {
            Capsule()
                .fill(isLit ? AnyShapeStyle(accent.gradient) : AnyShapeStyle(Color.white.opacity(0.14)))
                .frame(width: 6, height: height)
                .shadow(color: isLit ? accent.light.opacity(0.4) : .clear, radius: 4)
                .frame(width: 14, height: 28, alignment: .bottom)
                .hoverHighlight(RoundedRectangle(cornerRadius: 4, style: .continuous), isActive: !isLit)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("Fan speed \(level.level ?? 0)")
        .accessibilityAddTraits(level == speed ? .isSelected : [])
    }

    private func pill(_ value: FanSpeed, spoken: LocalizedStringKey, @ViewBuilder label: () -> some View) -> some View {
        let isSelected = value == speed
        return Button {
            onSelect(value)
        } label: {
            label()
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isSelected ? Ink.frost : Ink.mist)
                .frame(height: 24)
                .background(Capsule().fill(isSelected ? accent.deep.opacity(0.35) : Color.white.opacity(0.05)))
                .overlay(Capsule().strokeBorder(isSelected ? accent.light.opacity(0.3) : .clear))
                .hoverHighlight(Capsule(), isActive: !isSelected)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(spoken)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
