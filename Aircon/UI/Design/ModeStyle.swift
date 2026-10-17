import AirconKit

/// How each mode and fan speed is named and drawn.
extension Mode {
    var title: String {
        switch self {
        case .cool: String(localized: "Cool")
        case .dry: String(localized: "Dry")
        case .fan: String(localized: "Fan", comment: "Mode that only moves air")
        case .auto: String(localized: "Auto", comment: "Automatic mode")
        case .heat: String(localized: "Heat")
        }
    }

    var symbol: String {
        switch self {
        case .cool: "snowflake"
        case .dry: "drop"
        case .fan: "fan"
        case .auto: "a.circle"
        case .heat: "sun.max"
        }
    }

    /// What the unit is doing, as the status line says it.
    var activity: String {
        switch self {
        case .cool: String(localized: "Cooling")
        case .dry: String(localized: "Drying")
        case .fan: String(localized: "Fan only")
        case .auto: String(localized: "Auto", comment: "Automatic mode")
        case .heat: String(localized: "Heating")
        }
    }
}

extension ACState {
    /// The status line's first words. Auto doesn't report whether it is cooling or heating,
    /// so it says what it aims for instead: "Holding 23°".
    var activity: String {
        guard isOn else { return String(localized: "Off", comment: "The unit is switched off") }
        guard mode == .auto else { return mode.activity }
        let degrees = setpoint.formatted(.number.precision(.fractionLength(0...1)))
        return String(localized: "Holding \(degrees)°", comment: "Status of automatic mode, e.g. Holding 23°")
    }
}

extension FanSpeed {
    /// How hard the air moves, 0…1, for the airflow animation.
    var intensity: Double {
        switch self {
        case .quiet: 0.2
        case .auto: 0.55
        default: 0.2 + Double(level ?? 3) * 0.16
        }
    }
}
