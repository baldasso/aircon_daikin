import AirconKit
import Observation

/// The editable list of units. Every change is saved, then the home is rebuilt from it.
@MainActor @Observable
final class DeviceLibrary {
    private(set) var devices: [DeviceConfig] = []
    private(set) var problem: String?

    private let registry: DeviceRegistry
    private let home: Home

    init(registry: DeviceRegistry, home: Home) {
        self.registry = registry
        self.home = home
    }

    func load() {
        do {
            devices = try registry.load()
            problem = nil
        } catch {
            problem = "Couldn't read your units from the keychain."
        }
        home.configure(devices)
    }

    func save(_ device: DeviceConfig) {
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index] = device
        } else {
            devices.append(device)
        }
        commit()
    }

    func remove(_ id: DeviceConfig.ID) {
        devices.removeAll { $0.id == id }
        commit()
    }

    private func commit() {
        do {
            try registry.save(devices)
            problem = nil
        } catch {
            problem = "Couldn't save your units to the keychain."
        }
        home.configure(devices)
    }
}
