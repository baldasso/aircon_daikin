/// CRC-16/CCITT seeded with 0xFFFF and inverted at the end, as the device firmware computes it.
enum CRC16 {
    static func checksum(_ bytes: some Sequence<UInt8>) -> UInt16 {
        var crc: UInt16 = 0xFFFF
        for byte in bytes {
            crc ^= UInt16(byte) << 8
            for _ in 0..<8 {
                crc = crc & 0x8000 != 0 ? (crc << 1) ^ 0x1021 : crc << 1
            }
        }
        return ~crc
    }
}
