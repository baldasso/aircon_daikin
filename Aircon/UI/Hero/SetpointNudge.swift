import AirconKit
import AppKit
import Observation

extension Room {
    /// One way to move the setpoint, shared by the drag, the stepper, the scroll wheel and the arrow keys:
    /// clamped to what the unit accepts, with a detent felt on the trackpad for every degree.
    /// Does nothing in fan only, where the unit has no temperature to aim for.
    /// Returns false when asked to go past 16° or 32°.
    @discardableResult
    func setSetpoint(_ value: Double) -> Bool {
        guard let state, state.mode.usesSetpoint else { return true }
        let current = state.setpoint
        let clamped = HeroScale.clamp(value)
        guard clamped != current else { return clamped == value }
        change { $0.setpoint = clamped }
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        return true
    }

    /// Reads the state at call time: a held key or button repeats faster than views re-render.
    func nudgeSetpoint(by degrees: Double) {
        guard let current = state?.setpoint else { return }
        if !setSetpoint(current + degrees) {
            SetpointLimit.shared.hit(degrees)
        }
    }
}

/// Pushing past the end of the range: the tape gives a little and springs back, and the trackpad knocks once,
/// so the limit is felt rather than just enforced. The hero watches `hits` to play the bounce.
@MainActor @Observable
final class SetpointLimit {
    static let shared = SetpointLimit()

    /// +1 past the top, -1 past the bottom.
    private(set) var direction: Double = 0
    private(set) var hits = 0
    @ObservationIgnored private var lastHit = Date.distantPast

    /// A held key, a drag or a long scroll keeps pushing; one knock per push is enough.
    func hit(_ degrees: Double) {
        let now = Date()
        defer { lastHit = now }
        guard now.timeIntervalSince(lastHit) > 0.4 else { return }
        direction = degrees > 0 ? 1 : -1
        hits += 1
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }
}
