import AirconKit
import SwiftUI

/// Five bars for fixed speeds, rising like a signal meter, plus Auto and Quiet.
struct FanControl: View {
    let speed: FanSpeed
    let accent: Accent
    let onSelect: (FanSpeed) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(String(localized: "fan.row.title", defaultValue: "Fan", comment: "Label of the fan speed row"))
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
            .frame(height: 26, alignment: .bottom)
            .padding(.trailing, 6)

            pill(.auto, title: "Auto", spoken: "Automatic fan speed")
            pill(.quiet, title: "Quiet", spoken: "Quiet fan speed")
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .well()
        .animation(Motion.snap, value: speed)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(String(localized: "fan.row.title", defaultValue: "Fan", comment: "Label of the fan speed row")))
    }

    private func bar(_ level: FanSpeed, height: CGFloat, isLit: Bool) -> some View {
        Button {
            onSelect(level)
        } label: {
            Capsule()
                .fill(isLit ? AnyShapeStyle(accent.gradient) : AnyShapeStyle(Color.white.opacity(0.14)))
                .frame(width: 6, height: height)
                .shadow(color: isLit ? accent.light.opacity(0.4) : .clear, radius: 4)
                .frame(width: 12, height: 26, alignment: .bottom)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("Fan speed \(level.level ?? 0)")
        .accessibilityAddTraits(level == speed ? .isSelected : [])
    }

    private func pill(_ value: FanSpeed, title: LocalizedStringKey, spoken: LocalizedStringKey) -> some View {
        let isSelected = value == speed
        return Button {
            onSelect(value)
        } label: {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isSelected ? Ink.frost : Ink.mist)
                .padding(.horizontal, 9)
                .frame(height: 24)
                .background(Capsule().fill(isSelected ? accent.deep.opacity(0.35) : Color.white.opacity(0.05)))
                .overlay(Capsule().strokeBorder(isSelected ? accent.light.opacity(0.3) : .clear))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(spoken)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
