import Foundation

public enum Mode: Int, CaseIterable, Sendable {
    case auto = 0, dry = 2, cool = 3, heat = 4, fan = 6

    /// Modes offered in the UI. The installed units are cooling-only, so heat is left out.
    public static let selectable: [Mode] = [.cool, .dry, .fan, .auto]
}

public enum FanSpeed: Int, CaseIterable, Sendable {
    case level1 = 3, level2 = 4, level3 = 5, level4 = 6, level5 = 7
    case auto = 17, quiet = 18

    public static let levels: [FanSpeed] = [.level1, .level2, .level3, .level4, .level5]

    /// 1–5 for a fixed speed, nil for auto and quiet.
    public var level: Int? { FanSpeed.levels.firstIndex(of: self).map { $0 + 1 } }
}

public struct ACState: Equatable, Sendable {
    public static let setpointRange: ClosedRange<Double> = 16...32

    public var isOn: Bool
    public var mode: Mode
    public var setpoint: Double
    public var fan: FanSpeed
    public var swing: Bool
    public var eco: Bool
    public var powerful: Bool
    public var roomTemperature: Double?
    public var outdoorTemperature: Double?

    public init(
        isOn: Bool, mode: Mode, setpoint: Double, fan: FanSpeed,
        swing: Bool = false, eco: Bool = false, powerful: Bool = false,
        roomTemperature: Double? = nil, outdoorTemperature: Double? = nil
    ) {
        self.isOn = isOn
        self.mode = mode
        self.setpoint = setpoint
        self.fan = fan
        self.swing = swing
        self.eco = eco
        self.powerful = powerful
        self.roomTemperature = roomTemperature
        self.outdoorTemperature = outdoorTemperature
    }

    /// What the unit will look like once `command` is applied; drives optimistic UI.
    public func applying(_ command: ACCommand) -> ACState {
        var next = self
        next.isOn = command.isOn ?? isOn
        next.mode = command.mode ?? mode
        next.setpoint = command.setpoint ?? setpoint
        next.fan = command.fan ?? fan
        next.swing = command.swing ?? swing
        next.eco = command.eco ?? eco
        next.powerful = command.powerful ?? powerful
        return next
    }
}

// MARK: - Wire format

extension ACState {
    init(wire data: Data) throws {
        let port = try JSONDecoder().decode(WireStatus.self, from: data).port1
        self.init(
            isOn: port.power == 1,
            mode: Mode(rawValue: port.mode) ?? .auto,
            setpoint: port.temperature,
            fan: FanSpeed(rawValue: port.fan) ?? .auto,
            swing: port.v_swing == 1,
            eco: port.econo == 1,
            powerful: port.powerchill == 1,
            roomTemperature: Self.sensorValue(port.sensors?.room_temp),
            outdoorTemperature: Self.sensorValue(port.sensors?.out_temp)
        )
    }

    /// The firmware reports 255 for a sensor it doesn't have.
    private static func sensorValue(_ raw: Double?) -> Double? {
        guard let raw, raw < 255 else { return nil }
        return raw
    }
}

private struct WireStatus: Decodable {
    struct Port: Decodable {
        struct Sensors: Decodable {
            let room_temp: Double?
            let out_temp: Double?
        }

        let power: Int
        let mode: Int
        let temperature: Double
        let fan: Int
        let v_swing: Int?
        let econo: Int?
        let powerchill: Int?
        let sensors: Sensors?
    }

    let port1: Port
}
