import Foundation
import Testing
@testable import AirconKit

/// Talks to real units. Runs only when AIRCON_LIVE points at a devices JSON file (the format `--import` reads).
/// It reads every unit, then nudges one setpoint by a degree and back, leaving power and mode alone.
struct LiveDeviceTests {
    static let devicesFile = ProcessInfo.processInfo.environment["AIRCON_LIVE"]

    static func devices() throws -> [DeviceConfig] {
        let data = try Data(contentsOf: URL(fileURLWithPath: try #require(devicesFile)))
        return try JSONDecoder().decode([DeviceConfig].self, from: data)
    }

    @Test(.enabled(if: devicesFile != nil))
    func readsEveryUnit() async throws {
        for config in try Self.devices() {
            let client = DeviceClient(host: config.host, key: try #require(config.deviceKey))
            let state = try await client.fetchState()
            #expect(ACState.setpointRange.contains(state.setpoint) || state.setpoint < 16, "\(config.name)")
        }
    }

    @Test(.enabled(if: devicesFile != nil))
    func setpointRoundTrip() async throws {
        let config = try #require(try Self.devices().first)
        let client = DeviceClient(host: config.host, key: try #require(config.deviceKey))
        let before = try await client.fetchState()
        let nudged = before.setpoint < 31 ? before.setpoint + 1 : before.setpoint - 1

        let changed = try await client.apply(ACCommand(setpoint: nudged))
        let restored = try await client.apply(ACCommand(setpoint: before.setpoint))

        #expect(changed.setpoint == nudged)
        #expect(restored.setpoint == before.setpoint)
        #expect(restored.isOn == before.isOn)
    }
}
