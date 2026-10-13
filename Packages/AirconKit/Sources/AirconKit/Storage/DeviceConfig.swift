import Foundation

/// A unit the user added: a display name, its `.local` hostname and its key (base64, as the app shows it).
public struct DeviceConfig: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var host: String
    public var key: String

    public init(id: UUID = UUID(), name: String, host: String, key: String) {
        self.id = id
        self.name = name
        self.host = host
        self.key = key
    }

    public var deviceKey: DeviceKey? { DeviceKey(base64: key) }
}

extension DeviceConfig {
    private enum CodingKeys: String, CodingKey {
        case id, name, host, key
    }

    /// Hand-written device files may leave out the id; one is assigned on load.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        host = try container.decode(String.self, forKey: .host)
        key = try container.decode(String.self, forKey: .key)
    }
}
