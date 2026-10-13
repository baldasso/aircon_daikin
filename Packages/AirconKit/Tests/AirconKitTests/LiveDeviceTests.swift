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

extension LiveDeviceTests {
    /// Swaps every I/l and O/0 in a real key, as a hurried copy might, and expects the check to recover it.
    @Test(.enabled(if: devicesFile != nil))
    func keyCheckRecoversALookAlikeTypo() async throws {
        let config = try #require(try Self.devices().first { $0.key.contains(where: { "IlO0".contains($0) }) })
        let swapped = String(config.key.map { ["I": "l", "l": "I", "O": "0", "0": "O"][$0] ?? $0 })
        #expect(swapped != config.key)

        guard case .valid(let key, _) = await KeyCheck.run(swapped, host: config.host) else {
            Issue.record("expected the swapped key to be recovered")
            return
        }
        #expect(key == config.key)
        #expect(await KeyCheck.run("AAECAwQFBgcICQoLDA0ODw==", host: config.host) == .wrongKey)
    }
}
