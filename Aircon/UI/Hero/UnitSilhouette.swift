import SwiftUI

/// The wall unit in miniature. Its flap swings open on a spring when the unit starts.
struct UnitSilhouette: View {
    let isOn: Bool
    let accent: Accent

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            casing(RoundedRectangle(cornerRadius: 11, style: .continuous))
            flap
        }
        .animation(reduceMotion ? .easeOut(duration: 0.25) : .spring(response: 0.9, dampingFraction: 0.62), value: isOn)
        .accessibilityHidden(true)
    }

    private func casing(_ shape: RoundedRectangle) -> some View {
        shape
            .fill(LinearGradient(
                colors: [Color.white.opacity(0.17), Color.white.opacity(0.05)],
                startPoint: .top, endPoint: .bottom
            ))
            .overlay(shape.strokeBorder(Color.white.opacity(0.12)))
            .overlay(alignment: .top) {
                // A highlight along the top edge, where light from the room catches the casing.
                Capsule().fill(Color.white.opacity(0.22)).frame(height: 1).padding(.horizontal, 14).padding(.top, 1)
            }
            .overlay(alignment: .bottomTrailing) { indicator }
            .frame(width: 186, height: 36)
    }

    private var indicator: some View {
        Circle()
            .fill(isOn ? accent.light : Color.white.opacity(0.22))
            .frame(width: 4.5, height: 4.5)
            .shadow(color: isOn ? accent.light : .clear, radius: 5)
            .padding(.trailing, 12)
            .padding(.bottom, 9)
            .animation(Motion.tint, value: isOn)
    }

    /// Closed, the flap sits flush under the casing. Open, it tilts out and a dark vent shows behind it.
    private var flap: some View {
        ZStack(alignment: .top) {
            Capsule()
                .fill(Color.black.opacity(isOn ? 0.55 : 0))
                .frame(width: 160, height: isOn ? 5 : 0)
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color.white.opacity(0.32), Color.white.opacity(0.12)],
                    startPoint: .top, endPoint: .bottom
                ))
                .overlay(alignment: .bottom) {
                    Capsule().fill(accent.light.opacity(isOn ? 0.55 : 0)).frame(height: 1).padding(.horizontal, 10)
                }
                .frame(width: 170, height: 10)
                .rotation3DEffect(.degrees(isOn ? -38 : 0), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.4)
                .offset(y: isOn ? 3 : -5)
        }
        .frame(height: 14, alignment: .top)
    }
}
