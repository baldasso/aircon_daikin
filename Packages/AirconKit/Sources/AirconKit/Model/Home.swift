import Foundation
import Observation

/// All rooms, and how often to poll them: briskly while someone is looking, rarely otherwise.
@MainActor @Observable
public final class Home {
    public struct PollSchedule: Sendable {
        public var active: Duration
        public var idle: Duration

        public init(active: Duration = .seconds(4), idle: Duration = .seconds(120)) {
            self.active = active
            self.idle = idle
        }
    }

    public private(set) var rooms: [Room] = []
    public var selectedID: UUID?

    /// True while the panel is on screen. Opening it refreshes at once and speeds polling up.
    public var isActive = false {
        didSet { if isActive != oldValue { startPolling() } }
    }

    public var selectedRoom: Room? { rooms.first { $0.id == selectedID } ?? rooms.first }
    public var anyOn: Bool { rooms.contains { $0.state?.isOn == true } }

    private let schedule: PollSchedule
    private let makeDevice: (DeviceConfig) -> (any ACDevice)?
    private var pollTask: Task<Void, Never>?

    public init(schedule: PollSchedule = PollSchedule(), makeDevice: @escaping (DeviceConfig) -> (any ACDevice)?) {
        self.schedule = schedule
        self.makeDevice = makeDevice
    }

    public func configure(_ devices: [DeviceConfig]) {
        rooms = devices.compactMap { config in
            makeDevice(config).map {
                Room(id: config.id, name: config.name, device: $0, modes: Mode.offered(canHeat: config.canHeat))
            }
        }
        if selectedRoom?.id != selectedID { selectedID = rooms.first?.id }
        startPolling()
    }

    public func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            for room in rooms {
                group.addTask { await room.refresh() }
            }
        }
    }

    public func stop() {
        pollTask?.cancel()
        pollTask = nil
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled, let self {
                await refreshAll()
                try? await Task.sleep(for: isActive ? schedule.active : schedule.idle)
            }
        }
    }
}
