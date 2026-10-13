import AirconKit
import AppIntents

// Each intent is a thin shell over `Room.send` / `Room.currentState`; the logic lives (and is tested) in AirconKit.
// They run in the app's process, on the units in `IntentContext`.

struct TurnOnIntent: AppIntent {
    static let title: LocalizedStringResource = "Turn On Air Conditioner"
    static let description = IntentDescription("Turns on the air conditioner in a room.")

    @Parameter(title: "Room") var room: RoomEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Turn on \(\.$room)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let state = try await IntentContext.room(for: room).send { $0.isOn = true }
        return .result(dialog: "\(room.name) is on, set to \(Int(state.setpoint))°.")
    }
}

struct TurnOffIntent: AppIntent {
    static let title: LocalizedStringResource = "Turn Off Air Conditioner"
    static let description = IntentDescription("Turns off the air conditioner in a room.")

    @Parameter(title: "Room") var room: RoomEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Turn off \(\.$room)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        _ = try await IntentContext.room(for: room).send { $0.isOn = false }
        return .result(dialog: "\(room.name) is off.")
    }
}

struct SetTemperatureIntent: AppIntent {
    static let title: LocalizedStringResource = "Set Temperature"
    static let description = IntentDescription("Sets the temperature a room's air conditioner aims for. It doesn't turn the unit on.")

    @Parameter(title: "Room") var room: RoomEntity
    @Parameter(title: "Temperature", inclusiveRange: (16, 32)) var temperature: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Set \(\.$room) to \(\.$temperature)°")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let state = try await IntentContext.room(for: room).send { $0.setpoint = Double(temperature) }
        return .result(dialog: state.isOn
            ? "\(room.name) is set to \(temperature)°."
            : "\(room.name) is set to \(temperature)°. It's off; turn it on to start.")
    }
}

struct RoomStatusIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Room Status"
    static let description = IntentDescription("Tells whether a room's air conditioner is running, its temperature and the room's.")

    @Parameter(title: "Room") var room: RoomEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Get the status of \(\.$room)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Bool> {
        let state = try await IntentContext.room(for: room).currentState()
        return .result(value: state.isOn, dialog: IntentDialog(Self.dialog(room: room.name, state: state)))
    }

    static func dialog(room: String, state: ACState) -> LocalizedStringResource {
        let set = Int(state.setpoint)
        switch (state.isOn, state.roomTemperature.map { Int($0) }) {
        case (true, let inside?): return "\(room): \(state.mode.activity.lowercased()) at \(set)°. It's \(inside)° in the room."
        case (true, nil): return "\(room): \(state.mode.activity.lowercased()) at \(set)°."
        case (false, let inside?): return "\(room) is off. It's \(inside)° in the room."
        case (false, nil): return "\(room) is off."
        }
    }
}

struct TurnOffAllIntent: AppIntent {
    static let title: LocalizedStringResource = "Turn Off All Air Conditioners"
    static let description = IntentDescription("Turns off every air conditioner that is running.")


    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        IntentContext.library.loadIfNeeded()
        let result = await IntentContext.home.turnOffAll()
        if let first = result.unreachable.first {
            throw RoomError.unreachable(first.name)
        }
        switch result.turnedOff.count {
        case 0: return .result(dialog: "Everything was already off.")
        case 1: return .result(dialog: "Turned off \(result.turnedOff[0].name).")
        case let count: return .result(dialog: "Turned off \(count) air conditioners.")
        }
    }
}
