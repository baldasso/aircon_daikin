import AirconKit
import SwiftUI

/// Everything for one room: the hero, then mode, fan, extras and power.
struct RoomControls: View {
    let room: Room

    @Environment(\.panelIsVisible) private var visible

    private static let placeholder = ACState(isOn: false, mode: .cool, setpoint: 22, fan: .auto)

    var body: some View {
        let state = room.state ?? Self.placeholder
        let modeAccent = Accent.of(state.mode)
        let accent = Accent.of(room.state)

        VStack(spacing: 10) {
            ClimateHero(room: room)
                .entrance(1, shown: visible)

            Group {
                ModeBar(modes: room.modes, selection: state.mode, accent: modeAccent) { mode in room.change { $0.mode = mode } }
                    .entrance(2, shown: visible)
                FanControl(speed: state.fan, accent: accent) { speed in room.change { $0.fan = speed } }
                    .entrance(3, shown: visible)
                FeatureRow(state: state, accent: accent, room: room)
                    .entrance(4, shown: visible)
                PowerButton(isOn: state.isOn, accent: modeAccent) { room.change { $0.isOn = !state.isOn } }
                    .entrance(5, shown: visible)
            }
            .disabled(room.state == nil)
            .opacity(room.state == nil ? 0.4 : 1)
        }
    }
}
