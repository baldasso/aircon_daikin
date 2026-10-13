import AirconKit
import SwiftUI

/// One tab per room. A lit dot means that room's unit is running.
struct RoomTabs: View {
    let rooms: [Room]
    @Binding var selection: UUID?

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 2) {
            ForEach(rooms) { room in
                tab(room, isSelected: room.id == (selection ?? rooms.first?.id))
            }
        }
        .padding(3)
        .well(radius: 17)
        .animation(Motion.snap, value: selection)
    }

    private func tab(_ room: Room, isSelected: Bool) -> some View {
        Button {
            selection = room.id
        } label: {
            HStack(spacing: 6) {
                RunningDot(state: room.state)
                Text(room.name)
                    .font(Typeface.label)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
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
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(room.name), \(room.state?.isOn == true ? "on" : "off")")
    }
}

private struct RunningDot: View {
    let state: ACState?

    var body: some View {
        let isOn = state?.isOn == true
        let accent = state.map { Accent.of($0.mode) } ?? .slate
        Circle()
            .fill(isOn ? accent.light : Color.white.opacity(0.18))
            .frame(width: 6, height: 6)
            .shadow(color: isOn ? accent.light.opacity(0.9) : .clear, radius: 4)
            .animation(Motion.tint, value: isOn)
    }
}
