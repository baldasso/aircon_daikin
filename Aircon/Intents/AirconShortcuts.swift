import AppIntents

/// What Siri understands without the user setting anything up. Phrases must name the app;
/// the Portuguese ones are in AppShortcuts.xcstrings.
struct AirconShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TurnOnIntent(),
            phrases: [
                "Turn on \(\.$room) with \(.applicationName)",
                "Turn on the \(\.$room) air conditioner with \(.applicationName)",
                "\(.applicationName) turn on \(\.$room)",
            ],
            shortTitle: "Turn On",
            systemImageName: "power"
        )
        AppShortcut(
            intent: TurnOffIntent(),
            phrases: [
                "Turn off \(\.$room) with \(.applicationName)",
                "Turn off the \(\.$room) air conditioner with \(.applicationName)",
                "\(.applicationName) turn off \(\.$room)",
            ],
            shortTitle: "Turn Off",
            systemImageName: "power.dotted"
        )
        AppShortcut(
            intent: SetTemperatureIntent(),
            phrases: [
                "Set the \(\.$room) temperature with \(.applicationName)",
                "\(.applicationName) set \(\.$room) temperature",
            ],
            shortTitle: "Set Temperature",
            systemImageName: "thermometer.medium"
        )
        AppShortcut(
            intent: RoomStatusIntent(),
            phrases: [
                "How is \(\.$room) in \(.applicationName)",
                "\(.applicationName) status of \(\.$room)",
            ],
            shortTitle: "Room Status",
            systemImageName: "air.conditioner.horizontal"
        )
        AppShortcut(
            intent: TurnOffAllIntent(),
            phrases: [
                "Turn off all air conditioners with \(.applicationName)",
                "\(.applicationName) turn everything off",
            ],
            shortTitle: "Turn Off All",
            systemImageName: "power.circle"
        )
    }
}
