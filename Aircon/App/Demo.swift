import AirconKit
import Foundation
import Synchronization

/// Fake units for screenshots and design work (`AIRCON_DEMO=1`).
final class DemoDevice: ACDevice {
    private let state: Mutex<ACState>

    init(name: String) {
        state = Mutex(Self.initialState[name] ?? ACState(isOn: false, mode: .cool, setpoint: 22, fan: .auto))
    }

    private static let initialState: [String: ACState] = [
        "Sala": ACState(isOn: true, mode: .cool, setpoint: 21, fan: .level3, swing: true, roomTemperature: 24),
        "Suíte": ACState(isOn: false, mode: .cool, setpoint: 20, fan: .quiet, roomTemperature: 22),
        "Hóspede": ACState(isOn: true, mode: .dry, setpoint: 23, fan: .auto, roomTemperature: 25),
    ]

    func fetchState() async throws -> ACState {
        try await Task.sleep(for: .milliseconds(120))
        return state.withLock { $0 }
    }

    func apply(_ command: ACCommand) async throws -> ACState {
        try await Task.sleep(for: .milliseconds(180))
        return state.withLock { current in
            current = current.applying(command)
            return current
        }
    }
}

struct DemoStore: BlobStore {
    func read() throws -> Data? {
        try JSONEncoder().encode(["Sala", "Suíte", "Hóspede"].map {
            DeviceConfig(name: $0, host: "\($0).local", key: "AAECAwQFBgcICQoLDA0ODw==")
        })
    }

    func write(_ data: Data) throws {}
}
