import SwiftUI

/// First run: the unit starts up on its own to show what the app does, then two ways in.
struct WelcomeView: View {
    let addUnit: () -> Void
    let tryDemo: () -> Void

    @Environment(\.panelIsVisible) private var visible
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var running = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                AirflowField(
                    style: AirflowField.Style(intensity: 0.55, droplets: false, swing: true),
                    color: Accent.glacier.light,
                    running: running && visible && !reduceMotion
                )
                .padding(.top, 50)
                .opacity(running ? 1 : 0)
                UnitSilhouette(isOn: running, accent: .glacier)
                    .padding(.top, 20)
            }
            .frame(height: 220)
            .entrance(1, shown: visible)

            VStack(spacing: 10) {
                Text("Your air conditioners, one click away")
                    .font(Typeface.numeral(26))
                    .foregroundStyle(Ink.frost)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text("Control the Daikin units you set up in the Daikin Smart AC app, right from the menu bar. Everything stays on your Wi-Fi.")
                    .font(.system(size: 13))
                    .foregroundStyle(Ink.mist)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)
            .entrance(2, shown: visible)

            // The actions follow the pitch directly; only the legal note sits at the bottom.
            VStack(spacing: 8) {
                Button("Add your first unit", action: addUnit)
                    .buttonStyle(PrimaryButtonStyle(accent: .glacier))
                Button("Try a demo", action: tryDemo)
                    .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.top, 28)
            .entrance(3, shown: visible)

            Spacer(minLength: 12)

            Text("Not affiliated with Daikin.")
                .font(.system(size: 11))
                .foregroundStyle(Ink.mist)
                .entrance(4, shown: visible)
        }
        .onChange(of: visible, initial: true) { _, isVisible in
            startUp(isVisible)
        }
    }

    /// The flap opens a beat after the panel appears, so the motion reads as the unit starting.
    private func startUp(_ isVisible: Bool) {
        guard isVisible else {
            running = false
            return
        }
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            running = true
        }
    }
}
