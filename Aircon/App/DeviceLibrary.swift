import AirconKit
import Foundation
import Observation

/// The editable list of units. Every change is saved, then the home is rebuilt from it.
/// The demo swaps in pretend units without touching what is saved.
@MainActor @Observable
final class DeviceLibrary {
    private(set) var devices: [DeviceConfig] = []
    private(set) var problem: String?
    private(set) var isDemo = false
    private(set) var isLoaded = false

    /// Called whenever the set of rooms changes, so Siri learns the new room names.
    var onRoomsChange: (() -> Void)?

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
            problem = String(localized: "Couldn't read your units from the keychain.")
        }
        isLoaded = true
        show(devices)
    }

    /// Siri can launch the app straight into an intent, before the launch sequence has loaded anything.
    func loadIfNeeded() {
        if !isLoaded { load() }
    }

    func startDemo() {
        isDemo = true
        show(Demo.units)
    }

    func exitDemo() {
        isDemo = false
        show(devices)
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
            problem = String(localized: "Couldn't save your units to the keychain.")
        }
        isDemo = false
        show(devices)
    }

    private func show(_ units: [DeviceConfig]) {
        home.configure(units)
        onRoomsChange?()
    }
}
