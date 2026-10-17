import AirconKit
import Foundation

/// How this run was started. Development switches come from the environment so a normal launch has none.
///
/// - `--import <file>`: add the units in a JSON file to the keychain, then quit.
/// - `AIRCON_DEMO=1`: start in the demo.
/// - `AIRCON_DEVICES_FILE=<path>`: read units from a file instead of the keychain (unsandboxed builds only).
/// - `AIRCON_SHOW=controls|settings`: open the panel on launch.
/// - `AIRCON_ROOM=<name>`: select that room first.
/// - `AIRCON_ADD=<host>`: open settings adding that unit.
/// - `AIRCON_KEYCHAIN_SERVICE=<name>`: use another keychain item (tests).
struct LaunchOptions {
    private let environment = ProcessInfo.processInfo.environment
    private let arguments = ProcessInfo.processInfo.arguments

    var startsInDemo: Bool { environment["AIRCON_DEMO"] == "1" }

    var importFile: String? {
        guard let flag = arguments.firstIndex(of: "--import"), arguments.indices.contains(flag + 1) else { return nil }
        return arguments[flag + 1]
    }

    var initialScreen: PanelState.Screen? {
        environment["AIRCON_SHOW"].flatMap(PanelState.Screen.init(rawValue:))
    }

    var initialRoom: String? { environment["AIRCON_ROOM"] }

    var addingHost: String? { environment["AIRCON_ADD"] }

    func makeRegistry() -> DeviceRegistry {
        if let path = environment["AIRCON_DEVICES_FILE"] {
            return DeviceRegistry(store: FileBlobStore(url: URL(fileURLWithPath: path)))
        }
        // Demo runs (screenshots, UI tests) never read the keychain: each fresh build would ask for access again.
        if startsInDemo {
            return DeviceRegistry(store: FileBlobStore(url: FileManager.default.temporaryDirectory.appending(path: "aircon-demo-devices.json")))
        }
        let service = environment["AIRCON_KEYCHAIN_SERVICE"] ?? "dev.baldasso.aircon"
        return DeviceRegistry(store: KeychainBlobStore(service: service, account: "devices"))
    }

    static func makeDevice(_ config: DeviceConfig) -> (any ACDevice)? {
        if Demo.isDemoHost(config.host) { return DemoDevice(host: config.host) }
        return config.deviceKey.map { DeviceClient(host: config.host, key: $0) }
    }
}
