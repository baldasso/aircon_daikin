import AirconKit
import Foundation

/// How this run was started. Development switches come from the environment so a normal launch has none.
///
/// - `--import <file>`: add the units in a JSON file to the keychain, then quit.
/// - `AIRCON_DEMO=1`: fake units, nothing touches the network or the keychain.
/// - `AIRCON_DEVICES_FILE=<path>`: read units from a file instead of the keychain.
/// - `AIRCON_SHOW=controls|settings`: open the panel on launch.
/// - `AIRCON_ROOM=<name>`: select that room first.
struct LaunchOptions {
    private let environment = ProcessInfo.processInfo.environment
    private let arguments = ProcessInfo.processInfo.arguments

    var isDemo: Bool { environment["AIRCON_DEMO"] == "1" }

    var importFile: String? {
        guard let flag = arguments.firstIndex(of: "--import"), arguments.indices.contains(flag + 1) else { return nil }
        return arguments[flag + 1]
    }

    var initialScreen: PanelState.Screen? {
        environment["AIRCON_SHOW"].flatMap(PanelState.Screen.init(rawValue:))
    }

    var initialRoom: String? { environment["AIRCON_ROOM"] }

    func makeRegistry() -> DeviceRegistry {
        if isDemo { return DeviceRegistry(store: DemoStore()) }
        if let path = environment["AIRCON_DEVICES_FILE"] {
            return DeviceRegistry(store: FileBlobStore(url: URL(fileURLWithPath: path)))
        }
        return DeviceRegistry(store: KeychainBlobStore(service: "dev.baldasso.aircon", account: "devices"))
    }

    var makeDevice: (DeviceConfig) -> (any ACDevice)? {
        if isDemo { return { DemoDevice(name: $0.name) } }
        return { config in config.deviceKey.map { DeviceClient(host: config.host, key: $0) } }
    }
}
