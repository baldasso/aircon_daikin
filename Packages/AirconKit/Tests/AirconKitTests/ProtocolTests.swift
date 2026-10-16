import Foundation
import Testing
@testable import AirconKit

/// Vectors come from `openssl enc -aes-128-cfb` and an independent CRC implementation that matched real frames.
struct ProtocolTests {
    let key = DeviceKey(base64: "AAECAwQFBgcICQoLDA0ODw==")!
    let iv = Data(16..<32)

    @Test func crcMatchesTheCCITTCheckValueInverted() {
        #expect(CRC16.checksum(Array("123456789".utf8)) == 0xD64E)
    }

    @Test func cipherMatchesOpenSSL() throws {
        let ciphertext = try AESCFB.apply(.encrypt, to: Data(#"{"port1":{"power":1}}BZ"#.utf8), key: key.bytes, iv: iv)
        #expect(ciphertext.hex == "7cdc9f1b93a1324caa75cc61e1e3f7e1aba40ff2561b5a")
    }

    @Test func opensAResponseFrame() throws {
        let frame = "EBESExQVFhcYGRobHB0eH5V83J8bk6EyTKp1zGHh4/fhq6QPowk0b0FbQtv/k8BcGDUTP7FLqZwhQhdtmCw6JmgM0uXSe52TL4ah4fKmnaC8"
            + "HBxZjaT5HL06zGyUvJ2QLXdnlGUAhVZUZZqlkxuOJQX1LMC61J8hxWxRzAfpxsHD9kKEIKFOvygZauWpLIjWaCJGlLplQlMvUai33t9lv5HarxAgz/7X"
        let state = try ACState(wire: Frame.open(frame, key: key))
        #expect(state == ACState(isOn: true, mode: .cool, setpoint: 20, fan: .auto, swing: true, roomTemperature: 22))
    }

    @Test func rejectsATamperedFrame() throws {
        var bytes = try #require(Data(base64Encoded: Frame.seal(Data("hello".utf8), key: key, iv: iv)))
        bytes[18] ^= 0x01
        #expect(throws: AirconError.checksumMismatch) { try Frame.open(bytes.base64EncodedString(), key: key) }
    }

    @Test func rejectsGarbage() {
        #expect(throws: AirconError.malformedFrame) { try Frame.open("not base64!", key: key) }
        #expect(throws: AirconError.malformedFrame) { try Frame.open("AAAA", key: key) }
    }

    @Test func sealedFrameDecryptsBackWithTheResponseLayout() throws {
        // Requests have no length byte; open() skips one, so prepend it to read a request back.
        var bytes = try #require(Data(base64Encoded: Frame.seal(Data("xhello".utf8), key: key, iv: iv)))
        #expect(bytes.prefix(16) == iv)
        bytes.removeLast(2)
        let plain = try AESCFB.apply(.decrypt, to: Data(bytes.dropFirst(16)), key: key.bytes, iv: iv)
        #expect(String(decoding: plain, as: UTF8.self) == "xhello")
    }

    @Test func keyMustBe16Bytes() {
        #expect(DeviceKey(base64: "AAECAw==") == nil)
        #expect(DeviceKey(base64: " ZmFrZWtleWZha2VrZXkxMg== ") != nil)
    }

    @Test func commandPayloadOnlyCarriesSetFieldsAndTheTerminator() throws {
        let payload = try ACCommand(isOn: true, setpoint: 21, swing: false).wirePayload()
        #expect(String(decoding: payload, as: UTF8.self) == #"{"port1":{"power":1,"temperature":21,"v_swing":0}}BZ"#)
    }

    @Test func missingSensorsReadAsNil() throws {
        let json = #"{"port1":{"power":0,"mode":9,"temperature":18,"fan":99,"sensors":{"room_temp":255,"out_temp":255}}}"#
        let state = try ACState(wire: Data(json.utf8))
        #expect(state.roomTemperature == nil)
        #expect(state.outdoorTemperature == nil)
        #expect(state.mode == .auto)
        #expect(state.fan == .auto)
    }

    @Test func httpBodyToleratesTheFirmwaresTabbedHeaders() throws {
        let response = "HTTP/1.1 200 OK\r\n\t\tContent-Type: application/json\r\n\t\tConnection: Closed\r\n\r\nABCD"
        #expect(try RawHTTP.body(of: Data(response.utf8)) == "ABCD")
        #expect(throws: AirconError.unexpectedResponse("HTTP/1.1 404 Not Found")) {
            try RawHTTP.body(of: Data("HTTP/1.1 404 Not Found\r\n\r\n".utf8))
        }
    }

    @Test func discoveredHostnameComesFromTheAPN() {
        #expect(DiscoveredDevice(apn: "DAIKIN:C3B2A1DDEEFF")?.id == "DAIKINA1B2C3")
        #expect(DiscoveredDevice(apn: "DAIKIN:9F8E7D112233")?.host == "DAIKIN7D8E9F.local")
        #expect(DiscoveredDevice(apn: "DAIKIN:12") == nil)
    }
}

extension Data {
    var hex: String { map { String(format: "%02x", $0) }.joined() }
}

struct ModeTests {
    @Test func onlyFanOnlyIgnoresTheSetpoint() {
        #expect(Mode.allCases.filter { !$0.usesSetpoint } == [.fan])
    }
}
