import AirconKit
import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Neutral inks: a winter night, frost and mist.
enum Ink {
    static let night = Color(hex: 0x0B1220)
    static let frost = Color(hex: 0xEEF4FA)
    static let mist = Color(hex: 0xA9B5C5)
    static let hairline = Color.white.opacity(0.08)
    static let well = Color.white.opacity(0.045)
    /// Solid stand-in for the glass when Reduce Transparency is on.
    static let solid = Color(hex: 0x141B29)

    /// Increase Contrast makes edges and trays readable instead of merely suggested.
    static func hairline(_ contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? .white.opacity(0.24) : hairline
    }

    static func well(_ contrast: ColorSchemeContrast) -> Color {
        contrast == .increased ? .white.opacity(0.09) : well
    }
}

/// Corner radii, concentric from the outside in: each one is its container's minus the gap between them.
enum Radius {
    static let panel: CGFloat = 26
    static let block: CGFloat = 20
    static let row: CGFloat = 16
    static let item: CGFloat = 12
}

/// The accent follows the unit: its mode picks the hue family, and switching it off drains it to slate.
struct Accent: Equatable {
    let light: Color
    let deep: Color

    static let glacier = Accent(light: Color(hex: 0x8FE1FF), deep: Color(hex: 0x2F6BFF))
    static let lagoon = Accent(light: Color(hex: 0x86EBDD), deep: Color(hex: 0x178CA4))
    static let breeze = Accent(light: Color(hex: 0xE4ECF5), deep: Color(hex: 0x6F819C))
    static let aurora = Accent(light: Color(hex: 0xC6B5FF), deep: Color(hex: 0x5B4FE8))
    static let ember = Accent(light: Color(hex: 0xFFC08A), deep: Color(hex: 0xE8564B))
    static let slate = Accent(light: Color(hex: 0xA7B0C0), deep: Color(hex: 0x3A4252))

    static func of(_ mode: Mode) -> Accent {
        switch mode {
        case .cool: glacier
        case .dry: lagoon
        case .fan: breeze
        case .auto: aurora
        case .heat: ember
        }
    }

    static func of(_ state: ACState?) -> Accent {
        guard let state, state.isOn else { return slate }
        return of(state.mode)
    }

    var gradient: LinearGradient {
        LinearGradient(colors: [light, deep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// New York for the one big number; SF for everything that has to be read quickly.
enum Typeface {
    static func numeral(_ size: CGFloat) -> Font { .system(size: size, weight: .light, design: .serif) }
    static let title = Font.system(size: 15, weight: .semibold)
    static let label = Font.system(size: 12, weight: .medium)
    static let caption = Font.system(size: 11.5, weight: .regular)
    static let tick = Font.system(size: 10, weight: .medium, design: .monospaced)
}

enum Motion {
    static let snap = Animation.snappy(duration: 0.28)
    static let settle = Animation.spring(response: 0.6, dampingFraction: 0.78)
    static let tint = Animation.smooth(duration: 0.8)
}

extension EnvironmentValues {
    /// False while the panel is off screen; continuous animations pause on it.
    @Entry var panelIsVisible = false
}
