import Foundation

/// The user's units, kept together as one JSON blob so the keychain asks for access at most once.
public struct DeviceRegistry: Sendable {
    private let store: any BlobStore

    public init(store: any BlobStore) {
        self.store = store
    }

    public func load() throws -> [DeviceConfig] {
        guard let data = try store.read() else { return [] }
        return try JSONDecoder().decode([DeviceConfig].self, from: data)
    }

    public func save(_ devices: [DeviceConfig]) throws {
        try store.write(JSONEncoder().encode(devices))
    }
}
