import AirconKit
import SwiftUI

/// One tab per room. A lit, filled dot means that room's unit is running; an empty ring, that it's off.
/// When the names don't all fit, only the selected room keeps its name; the others shrink to their initial.
struct RoomTabs: View {
    let rooms: [Room]
    @Binding var selection: UUID?

    @Namespace private var namespace

    var body: some View {
        ViewThatFits(in: .horizontal) {
            tabs(compact: false)
            tabs(compact: true)
        }
        .animation(Motion.snap, value: selection)
    }

    private func tabs(compact: Bool) -> some View {
        HStack(spacing: 2) {
            ForEach(rooms) { room in
                let isSelected = room.id == (selection ?? rooms.first?.id)
                tab(room, isSelected: isSelected, compact: compact && !isSelected)
            }
        }
        .padding(3)
        .well(radius: 17)
        .fixedSize()
    }

    private func tab(_ room: Room, isSelected: Bool, compact: Bool) -> some View {
        Button {
            selection = room.id
        } label: {
            HStack(spacing: compact ? 4 : 6) {
                RunningDot(state: room.state)
                Text(compact ? String(room.name.prefix(1)) : room.name)
                    .font(compact ? .system(size: 11, weight: .semibold) : Typeface.label)
                    .lineLimit(1)
            }
            .padding(.horizontal, compact ? 8 : 10)
            .frame(height: 28)
            .foregroundStyle(isSelected ? Ink.frost : Ink.mist)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.08)))
                        .matchedGeometryEffect(id: "selection", in: namespace)
                }
            }
            .hoverHighlight(Capsule(), isActive: !isSelected)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(room.name)
        .accessibilityLabel(room.state?.isOn == true ? "\(room.name), on" : "\(room.name), off")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct RunningDot: View {
    let state: ACState?

    var body: some View {
        let isOn = state?.isOn == true
        let accent = state.map { Accent.of($0.mode) } ?? .slate
        // Shape as well as color, so on and off can be told apart without seeing hue.
        Circle()
            .fill(isOn ? accent.light : .clear)
            .overlay(Circle().strokeBorder(isOn ? .clear : Color.white.opacity(0.4), lineWidth: 1))
            .frame(width: 6, height: 6)
            .shadow(color: isOn ? accent.light.opacity(0.9) : .clear, radius: 4)
            .animation(Motion.tint, value: isOn)
    }
}
