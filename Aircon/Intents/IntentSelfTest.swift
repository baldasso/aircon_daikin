#if DEBUG
import AirconKit
import AppIntents
import AppKit

/// `AIRCON_INTENT_SELFTEST=1` (Debug builds): runs the Siri intents in-process against the configured units
/// and prints what happened, then quits. It never turns a unit on: it reads status, re-sends each unit's
/// current setpoint, and turns off only units that are already off.
@MainActor
enum IntentSelfTest {
    static func run(home: Home, library: DeviceLibrary) async {
        library.loadIfNeeded()
        let rooms = try? await RoomQuery().suggestedEntities()
        report("rooms", rooms?.map(\.name).joined(separator: ", ") ?? "none")

        for entity in rooms ?? [] {
            await step("status \(entity.name)") {
                let intent = RoomStatusIntent()
                intent.room = entity
                _ = try await intent.perform()
                let state = try await IntentContext.room(for: entity).currentState()
                return String(localized: RoomStatusIntent.dialog(room: entity.name, state: state))
            }
            guard let state = home.room(id: entity.id)?.state else { continue }
            await step("set \(entity.name) to its current \(Int(state.setpoint))°") {
                let intent = SetTemperatureIntent()
                intent.room = entity
                intent.temperature = Int(state.setpoint)
                _ = try await intent.perform()
                return "setpoint now \(home.room(id: entity.id)?.state?.setpoint ?? -1)"
            }
            if !state.isOn {
                await step("turn off \(entity.name) (already off)") {
                    let intent = TurnOffIntent()
                    intent.room = entity
                    _ = try await intent.perform()
                    return "isOn now \(home.room(id: entity.id)?.state?.isOn ?? true)"
                }
            }
        }
        if home.rooms.allSatisfy({ $0.state?.isOn == false }) {
            await step("turn off all (all already off)") {
                _ = try await TurnOffAllIntent().perform()
                return "done"
            }
        }
        await step("lookup by spoken name") {
            let found = try await RoomQuery().entities(matching: home.rooms.first?.name.lowercased() ?? "")
            return found.map(\.name).joined(separator: ", ")
        }
        NSApp.terminate(nil)
    }

    private static func step(_ name: String, _ body: () async throws -> String) async {
        do {
            report("ok  " + name, try await body())
        } catch {
            report("ERR " + name, String(describing: error))
        }
    }

    private static func report(_ name: String, _ detail: String) {
        print("\(name): \(detail)")
        fflush(stdout)
    }
}
#endif
