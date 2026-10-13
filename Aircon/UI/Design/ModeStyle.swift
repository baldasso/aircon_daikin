import AirconKit

/// How each mode and fan speed is named and drawn.
extension Mode {
    var title: String {
        switch self {
        case .cool: "Cool"
        case .dry: "Dry"
        case .fan: "Fan"
        case .auto: "Auto"
        case .heat: "Heat"
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
        case .cool: "Cooling"
        case .dry: "Drying"
        case .fan: "Fan only"
        case .auto: "Auto"
        case .heat: "Heating"
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
