import AirconKit
import SwiftUI

struct ControlsScreen: View {
    @Bindable var home: Home
    let library: DeviceLibrary
    let openSettings: () -> Void

    @Environment(\.panelIsVisible) private var visible

    var body: some View {
        VStack(spacing: 14) {
            if let room = home.selectedRoom {
                header
                    .entrance(0, shown: visible)
                RoomControls(room: room)
                    .id(room.id)
                    .transition(.blurReplace)
            } else {
                WelcomeView(addUnit: openSettings, tryDemo: library.startDemo)
            }
        }
        .animation(Motion.settle, value: home.selectedRoom?.id)
        .padding(16)
    }

    private var header: some View {
        HStack(spacing: 8) {
            RoomTabs(rooms: home.rooms, selection: $home.selectedID)
            Spacer(minLength: 0)
            if library.isDemo {
                DemoBadge(exit: library.exitDemo)
            }
            Button(action: openSettings) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Ink.mist)
                    .frame(width: 30, height: 30)
                    .hoverHighlight(Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("Units and settings")
            .help(Text("Units and settings"))
        }
    }
}

/// Says the units are pretend, and is the way out.
private struct DemoBadge: View {
    let exit: () -> Void

    var body: some View {
        Button(action: exit) {
            HStack(spacing: 4) {
                Text("Demo")
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
            }
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundStyle(Accent.aurora.light)
            .padding(.horizontal, 8)
            .frame(height: 22)
            .background(Capsule().fill(Accent.aurora.deep.opacity(0.25)))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("Exit demo")
    }
}
