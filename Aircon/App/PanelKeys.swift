import AirconKit
import AppKit

/// Keyboard control while the panel is open, wherever focus is:
/// ↑ ↓ change the temperature, ← → and ⌘1…⌘9 switch rooms, ⌘, opens or closes settings.
@MainActor
struct PanelKeys {
    let home: Home
    let panel: PanelState

    private enum Key {
        static let left: UInt16 = 123, right: UInt16 = 124, down: UInt16 = 125, up: UInt16 = 126
    }

    /// Returns true when the key was used, so it doesn't also reach a control.
    func handle(_ event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        if modifiers == .command { return handleCommand(event.charactersIgnoringModifiers ?? "") }
        guard modifiers.isEmpty, panel.screen == .controls else { return false }

        switch event.keyCode {
        case Key.up: home.selectedRoom?.nudgeSetpoint(by: 1)
        case Key.down: home.selectedRoom?.nudgeSetpoint(by: -1)
        case Key.left: selectRoom(offset: -1)
        case Key.right: selectRoom(offset: 1)
        default: return false
        }
        return true
    }

    private func handleCommand(_ key: String) -> Bool {
        if key == "," {
            panel.screen = panel.screen == .controls ? .settings : .controls
            return true
        }
        guard panel.screen == .controls, let number = Int(key), (1...9).contains(number),
              home.rooms.indices.contains(number - 1) else { return false }
        home.selectedID = home.rooms[number - 1].id
        return true
    }

    private func selectRoom(offset: Int) {
        guard let current = home.selectedRoom, let index = home.rooms.firstIndex(where: { $0 === current }) else { return }
        let next = index + offset
        guard home.rooms.indices.contains(next) else { return }
        home.selectedID = home.rooms[next].id
    }
}
