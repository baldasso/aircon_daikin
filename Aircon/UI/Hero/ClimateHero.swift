import AirconKit
import AppKit
import SwiftUI

/// The signature: the indoor unit itself, air falling from its flap, and the setpoint you drag, step or arrow up or down.
struct ClimateHero: View {
    let room: Room

    @Environment(\.panelIsVisible) private var visible
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragOrigin: Double?
    @State private var hovering = false
    @State private var air = AirPhase()

    static let height: CGFloat = 262

    var body: some View {
        let state = room.state
        let accent = Accent.of(state)
        let isOn = state?.isOn == true

        ZStack {
            AirflowField(
                style: AirflowField.Style(state: state),
                color: accent.light,
                running: air.running && visible && !reduceMotion
            )
            .padding(.top, 58)
            // Starting, the air grows out of the flap; stopping, it keeps falling as it fades.
            .scaleEffect(x: 1, y: air.grown ? 1 : 0.3, anchor: .top)
            .offset(y: air.falling ? 36 : 0)
            // With Reduce Motion the air holds still as one frame rather than vanishing: it still says "running".
            .opacity(air.shown ? (reduceMotion ? 0.6 : 1) : 0)
            .onChange(of: isOn, initial: true) { wasOn, isOn in
                choreograph(isOn: isOn, animated: wasOn != isOn && !reduceMotion)
            }

            // Heating, a still warm glow pools under the flap; it costs nothing per frame.
            RadialGradient(colors: [Accent.ember.deep.opacity(0.28), .clear], center: .top, startRadius: 0, endRadius: 120)
                .padding(.top, 56)
                .opacity(isOn && state?.mode == .heat ? 1 : 0)
                .animation(Motion.tint, value: isOn && state?.mode == .heat)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                UnitSilhouette(isOn: isOn, accent: accent)
                    .padding(.top, 20)
                Spacer()
            }

            if let state {
                let adjustable = state.mode.usesSetpoint
                Readout(state: state, accent: accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(.leading, 20)
                    .padding(.bottom, 16)

                // Out of the way until the pointer is over the hero, so the number and the air stay the picture.
                SetpointStepper(setpoint: state.setpoint, accent: accent) { room.nudgeSetpoint(by: $0) }
                    .pointerStyle(.default)
                    .opacity(hovering && adjustable ? 1 : 0)
                    .allowsHitTesting(adjustable)
                    .scaleEffect(hovering || reduceMotion ? 1 : 0.92, anchor: .trailing)
                    .animation(Motion.snap, value: hovering)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 58)
                    .padding(.bottom, 16)

                TemperatureRuler(value: state.setpoint, pointsPerDegree: HeroScale.pointsPerDegree, accent: accent)
                    .frame(width: 52)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .animation(Motion.settle, value: state.setpoint)
                    .opacity(adjustable ? 1 : 0)
                    .animation(Motion.snap, value: adjustable)
            } else {
                LinkStatus(room: room)
                    .padding(.top, 60)
            }

            if state != nil, room.link == .offline {
                OfflineBadge()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(12)
            }
        }
        .frame(height: Self.height)
        .well(radius: Radius.block)
        .contentShape(Rectangle())
        .gesture(dragToSet(from: state))
        .pointerStyle(state?.mode.usesSetpoint == true ? .rowResize : .default)
        .onHover { hovering = $0 }
        .modifier(SetpointAccessibility(room: room, state: state))
    }

    /// State has to change inside `withAnimation` for the change to animate, so the phases are set here.
    private func choreograph(isOn: Bool, animated: Bool) {
        guard animated else {
            air = isOn ? .on : .off
            return
        }
        if isOn {
            air = AirPhase(running: true)
            withAnimation(AirPhase.start) { air = .on }
        } else {
            withAnimation(AirPhase.stop) { air = .stopping }
            Task {
                try? await Task.sleep(for: .milliseconds(850))
                // Unless it was turned back on meanwhile, freeze the timeline and reset for the next start.
                if air == .stopping { air = .off }
            }
        }
    }

    private func dragToSet(from state: ACState?) -> some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { drag in
                guard let state else { return }
                let origin = dragOrigin ?? state.setpoint
                dragOrigin = origin
                room.setSetpoint(HeroScale.value(from: origin, dragged: drag.translation.height))
            }
            .onEnded { _ in dragOrigin = nil }
    }
}

/// The air's part in turning on and off. The flap opens first, so the air starts a beat after it;
/// turning off, the timeline keeps running while the air drops away, then stops.
private struct AirPhase: Equatable {
    var running = false
    var shown = false
    var grown = false
    var falling = false

    static let off = AirPhase()
    static let on = AirPhase(running: true, shown: true, grown: true)
    /// Still moving, already falling and fading.
    static let stopping = AirPhase(running: true, grown: true, falling: true)

    static let start = Animation.easeOut(duration: 1.1).delay(0.45)
    static let stop = Animation.easeIn(duration: 0.8)
}

/// VoiceOver sees the hero as one temperature slider that also says what the unit is doing.
/// Until the unit has answered, its connection status and "Try again" are read instead.
private struct SetpointAccessibility: ViewModifier {
    let room: Room
    let state: ACState?

    func body(content: Content) -> some View {
        if let state, !state.mode.usesSetpoint {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(room.name))
                .accessibilityValue(Text(Readout.statusLine(of: state)))
        } else if let state {
            content.accessibilityRepresentation {
                Slider(value: binding(state), in: ACState.setpointRange, step: 1) {
                    Text("\(room.name) temperature")
                }
                .accessibilityValue(description(of: state))
            }
        } else {
            content.accessibilityElement(children: .contain)
        }
    }

    private func binding(_ state: ACState) -> Binding<Double> {
        Binding(get: { state.setpoint }, set: { value in
            room.change { $0.setpoint = HeroScale.clamp(value.rounded()) }
        })
    }

    private func description(of state: ACState) -> Text {
        let activity = state.isOn ? state.mode.activity : String(localized: "Off", comment: "The unit is switched off")
        let offline = room.link == .offline ? String(localized: ", offline") : ""
        guard let roomTemperature = state.roomTemperature else {
            return Text("\(Int(state.setpoint)) degrees, \(activity)\(offline)")
        }
        return Text("\(Int(state.setpoint)) degrees, \(activity), room \(Int(roomTemperature)) degrees\(offline)")
    }
}

/// Dragging maps distance to degrees at the same scale the ruler is drawn, so the tape follows the finger.
enum HeroScale {
    static let pointsPerDegree: CGFloat = 18

    static func value(from origin: Double, dragged dy: CGFloat) -> Double {
        clamp((origin - Double(dy / pointsPerDegree)).rounded())
    }

    static func clamp(_ value: Double) -> Double {
        min(max(value, ACState.setpointRange.lowerBound), ACState.setpointRange.upperBound)
    }
}

private struct Readout: View {
    let state: ACState
    let accent: Accent

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 2) {
                Text(state.setpoint.formatted(.number.precision(.fractionLength(0...1))))
                    .font(Typeface.numeral(92))
                    // Fan only has no temperature to reach: the number stays as a faint memory of the last one.
                    .foregroundStyle(Ink.frost.opacity(!state.mode.usesSetpoint ? 0.35 : state.isOn ? 1 : 0.55))
                    .contentTransition(.numericText(value: state.setpoint))
                Text("°")
                    .font(Typeface.numeral(40))
                    .foregroundStyle(accent.light)
                    .padding(.top, 14)
            }
            .animation(Motion.snap, value: state.setpoint)

            Text(Self.statusLine(of: state))
                .font(Typeface.caption)
                .foregroundStyle(Ink.mist)
                .contentTransition(.opacity)
        }
    }

    static func statusLine(of state: ACState) -> String {
        let activity = state.isOn ? state.mode.activity : String(localized: "Off", comment: "The unit is switched off")
        guard let room = state.roomTemperature else { return activity }
        let degrees = room.formatted(.number.precision(.fractionLength(0...1)))
        return String(localized: "\(activity) · Room \(degrees)°", comment: "Status line, e.g. Cooling · Room 24°")
    }
}

/// Shown in place of the readout until the unit has answered once.
private struct LinkStatus: View {
    let room: Room

    var body: some View {
        VStack(spacing: 6) {
            switch room.link {
            case .connecting, .online:
                ProgressView().controlSize(.small)
                Text("Connecting to \(room.name)…")
                    .font(Typeface.caption)
                    .foregroundStyle(Ink.mist)
            case .offline:
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(Ink.mist)
                Text("Can't reach \(room.name)")
                    .font(Typeface.label)
                    .foregroundStyle(Ink.frost)
                Text("Check that it has power and is on this Wi-Fi.")
                    .font(Typeface.caption)
                    .foregroundStyle(Ink.mist)
                Button("Try again") { Task { await room.refresh() } }
                    .buttonStyle(.plain)
                    .font(Typeface.label)
                    .foregroundStyle(Accent.glacier.light)
                    .padding(.top, 4)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
    }
}

private struct OfflineBadge: View {
    var body: some View {
        Label("Offline", systemImage: "wifi.slash")
            .font(.system(size: 10.5, weight: .semibold))
            // System orange, not the heat accent: a warning must never read as a mode.
            .foregroundStyle(.orange)
            .padding(.horizontal, 8)
            .frame(height: 20)
            .background(Capsule().fill(Color.orange.opacity(0.16)))
    }
}
