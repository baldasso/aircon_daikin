import Foundation

/// A unit the user added: a display name, its `.local` hostname and its key (base64, as the app shows it).
public struct DeviceConfig: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var host: String
    public var key: String
    /// The Daikin app calls cooling-only units "Somente Frio"; the unit itself doesn't report it.
    public var canHeat: Bool

    public init(id: UUID = UUID(), name: String, host: String, key: String, canHeat: Bool = false) {
        self.id = id
        self.name = name
        self.host = host
        self.key = key
        self.canHeat = canHeat
    }

    public var deviceKey: DeviceKey? { DeviceKey(base64: key) }
}

extension DeviceConfig {
    private enum CodingKeys: String, CodingKey {
        case id, name, host, key, canHeat
    }

    /// Hand-written device files may leave out the id and heating; defaults are filled in on load.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        host = try container.decode(String.self, forKey: .host)
        key = try container.decode(String.self, forKey: .key)
        canHeat = try container.decodeIfPresent(Bool.self, forKey: .canHeat) ?? false
    }
}
