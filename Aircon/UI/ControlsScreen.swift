import AirconKit
import SwiftUI

struct ControlsScreen: View {
    @Bindable var home: Home
    let openSettings: () -> Void

    @Environment(\.panelIsVisible) private var visible

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                if !home.rooms.isEmpty {
                    RoomTabs(rooms: home.rooms, selection: $home.selectedID)
                }
                Spacer(minLength: 0)
                Button(action: openSettings) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Ink.mist)
                        .frame(width: 30, height: 30)
                        .contentShape(Circle())
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("Units and settings")
            }
            .entrance(0, shown: visible)

            if let room = home.selectedRoom {
                RoomControls(room: room)
                    .id(room.id)
                    .transition(.blurReplace)
            } else {
                EmptyHome(addUnit: openSettings)
            }
        }
        .animation(Motion.settle, value: home.selectedRoom?.id)
        .padding(16)
    }
}

private struct EmptyHome: View {
    let addUnit: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            UnitSilhouette(isOn: false, accent: .slate)
            Text("No units yet")
                .font(Typeface.title)
                .foregroundStyle(Ink.frost)
            Text("Add an air conditioner with the key from the Daikin Smart AC app.")
                .font(Typeface.caption)
                .foregroundStyle(Ink.mist)
                .multilineTextAlignment(.center)
            Button("Add a unit", action: addUnit)
                .buttonStyle(PrimaryButtonStyle(accent: .glacier))
                .padding(.top, 6)
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}
