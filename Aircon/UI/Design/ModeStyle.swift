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
        // The unit doesn't report which way it is going, so say what auto does rather than guess.
        case .auto: String(localized: "Cooling or heating", comment: "Status of automatic mode: the unit cools or heats as needed")
        case .heat: String(localized: "Heating")
        }
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
