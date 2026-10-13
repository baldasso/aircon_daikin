import Foundation
import Observation

public enum RoomError: Error, Equatable, Sendable {
    case unreachable(String)
}

/// One unit as the UI sees it: the last reported state plus edits not yet confirmed by the device.
@MainActor @Observable
public final class Room: Identifiable {
    public enum Link: Equatable, Sendable {
        case connecting, online, offline
    }

    public let id: UUID
    public let name: String
    public let modes: [Mode]
    public private(set) var reported: ACState?
    public private(set) var pending = ACCommand()
    public private(set) var link = Link.connecting

    /// The state to show: the device's last report with local edits applied on top.
    public var state: ACState? { reported?.applying(pending) }

    private let device: any ACDevice
    private let debounce: Duration
    private var flushTask: Task<Void, Never>?
    private var inFlight = 0

    public init(
        id: UUID, name: String, device: any ACDevice,
        modes: [Mode] = Mode.offered(canHeat: false), debounce: Duration = .milliseconds(350)
    ) {
        self.id = id
        self.name = name
        self.modes = modes
        self.device = device
        self.debounce = debounce
    }

    /// Applies an edit locally at once and sends it after a short pause, so a dial drag becomes one command.
    public func change(_ edit: (inout ACCommand) -> Void) {
        edit(&pending)
        flushTask?.cancel()
        flushTask = Task { [weak self, debounce] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            await self?.flush()
        }
    }

    public func refresh() async {
        guard isIdle else { return }
        do {
            let state = try await device.fetchState()
            // An edit may have started while the request was out; the device hasn't seen it yet.
            if isIdle { reported = state }
            link = .online
        } catch {
            link = .offline
        }
    }

    /// Applies an edit and sends it right away, returning what the unit reports. For Siri and Shortcuts,
    /// which need an answer now rather than after the debounce.
    public func send(_ edit: (inout ACCommand) -> Void) async throws -> ACState {
        edit(&pending)
        flushTask?.cancel()
        flushTask = nil
        await flush()
        guard link == .online, let state else { throw RoomError.unreachable(name) }
        return state
    }

    /// Asks the unit for its state now and returns it.
    public func currentState() async throws -> ACState {
        await refresh()
        guard link == .online, let state else { throw RoomError.unreachable(name) }
        return state
    }

    /// Sends pending edits now instead of waiting for the debounce. Used by tests and on quit.
    public func flush() async {
        let command = pending
        guard !command.isEmpty else { return }
        inFlight += 1
        defer { inFlight -= 1 }
        do {
            reported = try await device.apply(command)
            pending = pending.removing(command)
            link = .online
        } catch {
            // Roll the optimistic edit back so the UI never shows a state the unit doesn't have.
            pending = pending.removing(command)
            link = .offline
        }
    }

    private var isIdle: Bool { pending.isEmpty && inFlight == 0 }
}
