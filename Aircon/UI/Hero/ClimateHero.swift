import AirconKit
import AppKit
import SwiftUI

/// The signature: the indoor unit itself, air falling from its flap, and the setpoint you drag up or down.
struct ClimateHero: View {
    let room: Room

    @Environment(\.panelIsVisible) private var visible
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragOrigin: Double?

    static let height: CGFloat = 262

    var body: some View {
        let state = room.state
        let accent = Accent.of(state)
        let isOn = state?.isOn == true

        ZStack {
            AirflowField(
                style: AirflowField.Style(state: state),
                color: accent.light,
                running: isOn && visible && !reduceMotion
            )
            .padding(.top, 58)
            .opacity(isOn ? 1 : 0)
            .animation(.easeInOut(duration: isOn ? 1.2 : 0.6), value: isOn)

            VStack(spacing: 0) {
                UnitSilhouette(isOn: isOn, accent: accent)
                    .padding(.top, 20)
                Spacer()
            }

            if let state {
                Readout(state: state, accent: accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(.leading, 20)
                    .padding(.bottom, 16)

                TemperatureRuler(value: state.setpoint, pointsPerDegree: HeroScale.pointsPerDegree, accent: accent)
                    .frame(width: 52)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .animation(Motion.settle, value: state.setpoint)
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
        .well(radius: 22)
        .contentShape(Rectangle())
        .gesture(dragToSet(from: state))
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.upArrow) { step(by: 1, from: state) }
        .onKeyPress(.downArrow) { step(by: -1, from: state) }
        .modifier(SetpointAccessibility(room: room, state: state))
    }

    private func dragToSet(from state: ACState?) -> some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { drag in
                guard let state else { return }
                let origin = dragOrigin ?? state.setpoint
                dragOrigin = origin
                set(HeroScale.value(from: origin, dragged: drag.translation.height), current: state.setpoint)
            }
            .onEnded { _ in dragOrigin = nil }
    }

    private func step(by degrees: Double, from state: ACState?) -> KeyPress.Result {
        guard let state else { return .ignored }
        set(HeroScale.clamp(state.setpoint + degrees), current: state.setpoint)
        return .handled
    }

    private func set(_ value: Double, current: Double) {
        guard value != current else { return }
        room.change { $0.setpoint = value }
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }
}

/// VoiceOver sees the hero as one temperature slider that also says what the unit is doing.
/// Until the unit has answered, its connection status and "Try again" are read instead.
private struct SetpointAccessibility: ViewModifier {
    let room: Room
    let state: ACState?

    func body(content: Content) -> some View {
        if let state {
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
                    .foregroundStyle(Ink.frost.opacity(state.isOn ? 1 : 0.55))
                    .contentTransition(.numericText(value: state.setpoint))
                Text("°")
                    .font(Typeface.numeral(40))
                    .foregroundStyle(accent.light)
                    .padding(.top, 14)
            }
            .animation(Motion.snap, value: state.setpoint)

            Text(statusLine)
                .font(Typeface.caption)
                .foregroundStyle(Ink.mist)
                .contentTransition(.opacity)
        }
    }

    private var statusLine: String {
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
            .foregroundStyle(Accent.ember.light)
            .padding(.horizontal, 8)
            .frame(height: 20)
            .background(Capsule().fill(Accent.ember.deep.opacity(0.18)))
    }
}
