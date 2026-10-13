import AirconKit
import Foundation
import Synchronization

/// Pretend units, so anyone (App Review included) can try the app without a Daikin on the network.
enum Demo {
    private static let suffix = ".demo"

    static var units: [DeviceConfig] {
        [
            DeviceConfig(name: String(localized: "Living room"), host: "1" + suffix, key: "", canHeat: true),
            DeviceConfig(name: String(localized: "Bedroom"), host: "2" + suffix, key: ""),
            DeviceConfig(name: String(localized: "Guest room"), host: "3" + suffix, key: ""),
        ]
    }

    static func isDemoHost(_ host: String) -> Bool { host.hasSuffix(suffix) }

    static func initialState(host: String) -> ACState {
        switch host {
        case "1" + suffix: ACState(isOn: true, mode: .cool, setpoint: 21, fan: .level3, swing: true, roomTemperature: 24)
        case "3" + suffix: ACState(isOn: true, mode: .dry, setpoint: 23, fan: .auto, roomTemperature: 25)
        default: ACState(isOn: false, mode: .cool, setpoint: 20, fan: .quiet, roomTemperature: 22)
        }
    }
}

final class DemoDevice: ACDevice {
    private let state: Mutex<ACState>

    init(host: String) {
        state = Mutex(Demo.initialState(host: host))
    }

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
