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
        let short = Self.shortNames(rooms.map(\.name))
        return HStack(spacing: 2) {
            ForEach(Array(rooms.enumerated()), id: \.element.id) { index, room in
                let isSelected = room.id == (selection ?? rooms.first?.id)
                tab(room, isSelected: isSelected, short: compact && !isSelected ? short[index] : nil)
            }
        }
        .padding(3)
        .well(radius: 17)
        .fixedSize()
    }

    /// `short` is the abbreviation to show instead of the full name, when space is tight.
    private func tab(_ room: Room, isSelected: Bool, short: String?) -> some View {
        Button {
            selection = room.id
        } label: {
            HStack(spacing: short == nil ? 6 : 4) {
                RunningDot(state: room.state)
                Text(short ?? room.name)
                    .font(short == nil ? Typeface.label : .system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, short == nil ? 10 : 8)
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
            .focusRing(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(room.name)
        .accessibilityLabel(room.state?.isOn == true ? "\(room.name), on" : "\(room.name), off")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension RoomTabs {
    /// The shortest start of each name that no other name shares: Sala, Suíte, Hóspede → Sa, Su, H.
    static func shortNames(_ names: [String]) -> [String] {
        let folded = names.map { $0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil) }
        return names.indices.map { index in
            let others = folded.indices.filter { $0 != index }.map { folded[$0] }
            let length = (1...max(1, names[index].count)).first { length in
                !others.contains { $0.hasPrefix(folded[index].prefix(length)) }
            } ?? names[index].count
            return String(names[index].prefix(length))
        }
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
