import AirconKit
import AppKit

extension Room {
    /// One way to move the setpoint, shared by the drag, the stepper and the arrow keys:
    /// clamped to what the unit accepts, with a detent felt on the trackpad for every degree.
    /// Does nothing in fan only, where the unit has no temperature to aim for.
    func setSetpoint(_ value: Double) {
        guard let state, state.mode.usesSetpoint else { return }
        let current = state.setpoint
        let value = HeroScale.clamp(value)
        guard value != current else { return }
        change { $0.setpoint = value }
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }

    /// Reads the state at call time: a held key or button repeats faster than views re-render.
    func nudgeSetpoint(by degrees: Double) {
        guard let current = state?.setpoint else { return }
        setSetpoint(current + degrees)
    }
}
