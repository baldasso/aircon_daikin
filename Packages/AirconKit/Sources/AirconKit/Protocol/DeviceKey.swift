import Foundation

/// The 16-byte AES key the Daikin Smart AC app shows under Integrations → Home Assistant.
public struct DeviceKey: Hashable, Sendable {
    let bytes: Data

    public init?(base64: String) {
        guard let data = Data(base64Encoded: base64.trimmingCharacters(in: .whitespacesAndNewlines)),
              data.count == 16 else { return nil }
        bytes = data
    }
}
