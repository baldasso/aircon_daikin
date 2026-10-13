import Foundation

/// A partial change to send to the unit. Fields left nil are untouched.
public struct ACCommand: Equatable, Sendable {
    public var isOn: Bool?
    public var mode: Mode?
    public var setpoint: Double?
    public var fan: FanSpeed?
    public var swing: Bool?
    public var eco: Bool?
    public var powerful: Bool?

    public init(
        isOn: Bool? = nil, mode: Mode? = nil, setpoint: Double? = nil, fan: FanSpeed? = nil,
        swing: Bool? = nil, eco: Bool? = nil, powerful: Bool? = nil
    ) {
        self.isOn = isOn
        self.mode = mode
        self.setpoint = setpoint
        self.fan = fan
        self.swing = swing
        self.eco = eco
        self.powerful = powerful
    }

    public var isEmpty: Bool { self == ACCommand() }

    /// Drops the fields that still hold the value `sent` carried, keeping edits made after it left.
    public func removing(_ sent: ACCommand) -> ACCommand {
        ACCommand(
            isOn: isOn == sent.isOn ? nil : isOn,
            mode: mode == sent.mode ? nil : mode,
            setpoint: setpoint == sent.setpoint ? nil : setpoint,
            fan: fan == sent.fan ? nil : fan,
            swing: swing == sent.swing ? nil : swing,
            eco: eco == sent.eco ? nil : eco,
            powerful: powerful == sent.powerful ? nil : powerful
        )
    }
}

// MARK: - Wire format

extension ACCommand {
    /// The firmware expects `{"port1":{…}}` followed by a literal "BZ" terminator, then encryption.
    func wirePayload() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        var payload = try encoder.encode(WireCommand(port1: WirePort(self)))
        payload.append(contentsOf: Array("BZ".utf8))
        return payload
    }
}

private struct WireCommand: Encodable {
    let port1: WirePort
}

private struct WirePort: Encodable {
    let power: Int?
    let mode: Int?
    let temperature: Double?
    let fan: Int?
    let v_swing: Int?
    let econo: Int?
    let powerchill: Int?

    init(_ command: ACCommand) {
        power = command.isOn.map(Self.flag)
        mode = command.mode?.rawValue
        temperature = command.setpoint
        fan = command.fan?.rawValue
        v_swing = command.swing.map(Self.flag)
        econo = command.eco.map(Self.flag)
        powerchill = command.powerful.map(Self.flag)
    }

    private static func flag(_ value: Bool) -> Int { value ? 1 : 0 }
}
