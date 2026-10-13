import Foundation

/// The device's envelope: `base64(iv ‖ ciphertext ‖ crc16)`, CRC little-endian over everything before it.
/// Responses carry one extra length byte between the IV and the ciphertext; requests don't.
enum Frame {
    private static let ivLength = 16
    private static let responseHeaderLength = ivLength + 1
    private static let checksumLength = 2

    static func seal(_ plaintext: Data, key: DeviceKey, iv: Data = randomIV()) throws -> String {
        var frame = iv
        frame.append(try AESCFB.apply(.encrypt, to: plaintext, key: key.bytes, iv: iv))
        let crc = CRC16.checksum(frame)
        frame.append(contentsOf: [UInt8(crc & 0xFF), UInt8(crc >> 8)])
        return frame.base64EncodedString()
    }

    static func open(_ text: String, key: DeviceKey) throws -> Data {
        let frame = try decode(text)
        let body = frame.prefix(frame.count - checksumLength)
        let stored = UInt16(frame[frame.count - 2]) | UInt16(frame[frame.count - 1]) << 8
        guard CRC16.checksum(body) == stored else { throw AirconError.checksumMismatch }

        let iv = Data(frame.prefix(ivLength))
        let ciphertext = Data(body.dropFirst(responseHeaderLength))
        return try AESCFB.apply(.decrypt, to: ciphertext, key: key.bytes, iv: iv)
    }

    private static func decode(_ text: String) throws -> Data {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let frame = Data(base64Encoded: trimmed),
              frame.count > responseHeaderLength + checksumLength else { throw AirconError.malformedFrame }
        return frame
    }

    static func randomIV() -> Data {
        var generator = SystemRandomNumberGenerator()
        return Data((0..<ivLength).map { _ in UInt8.random(in: .min ... .max, using: &generator) })
    }
}
