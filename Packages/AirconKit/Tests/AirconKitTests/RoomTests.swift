import Foundation
import Synchronization
import Testing
@testable import AirconKit

/// An in-memory unit that records the commands it receives.
final class FakeDevice: ACDevice {
    private let storage: Mutex<(state: ACState, commands: [ACCommand], failing: Bool)>

    init(_ state: ACState) {
        storage = Mutex((state, [], false))
    }

    var commands: [ACCommand] { storage.withLock { $0.commands } }
    var current: ACState { storage.withLock { $0.state } }
    func setFailing(_ failing: Bool) { storage.withLock { $0.failing = failing } }
    func setState(_ state: ACState) { storage.withLock { $0.state = state } }

    func fetchState() async throws -> ACState {
        try storage.withLock { storage in
            if storage.failing { throw AirconError.timeout }
            return storage.state
        }
    }

    func apply(_ command: ACCommand) async throws -> ACState {
        try storage.withLock { storage in
            if storage.failing { throw AirconError.timeout }
            storage.commands.append(command)
            storage.state = storage.state.applying(command)
            return storage.state
        }
    }
}

@MainActor
struct RoomTests {
    let off = ACState(isOn: false, mode: .cool, setpoint: 20, fan: .auto, roomTemperature: 23)

    @Test func refreshLoadsTheReportedState() async {
        let room = Room(id: UUID(), name: "Living", device: FakeDevice(off))
        #expect(room.link == .connecting)
        await room.refresh()
        #expect(room.state == off)
        #expect(room.link == .online)
    }

    @Test func editsShowImmediatelyAndCoalesceIntoOneCommand() async throws {
        let device = FakeDevice(off)
        let room = Room(id: UUID(), name: "Living", device: device, debounce: .milliseconds(50))
        await room.refresh()

        room.change { $0.setpoint = 21 }
        room.change { $0.setpoint = 22 }
        room.change { $0.isOn = true }
        #expect(room.state?.setpoint == 22)
        #expect(room.state?.isOn == true)

        try await Task.sleep(for: .milliseconds(300))
        #expect(device.commands == [ACCommand(isOn: true, setpoint: 22)])
        #expect(room.pending.isEmpty)
        #expect(room.reported?.setpoint == 22)
    }

    @Test func refreshDoesNotOverwriteAnUnsentEdit() async {
        let device = FakeDevice(off)
        let room = Room(id: UUID(), name: "Living", device: device, debounce: .seconds(60))
        await room.refresh()
        room.change { $0.setpoint = 25 }
        device.setState(off.applying(ACCommand(setpoint: 18)))
        await room.refresh()
        #expect(room.state?.setpoint == 25)
    }

    @Test func failedSendRollsBackAndGoesOffline() async {
        let device = FakeDevice(off)
        let room = Room(id: UUID(), name: "Living", device: device, debounce: .seconds(60))
        await room.refresh()
        device.setFailing(true)
        room.change { $0.isOn = true }
        await room.flush()
        #expect(room.state?.isOn == false)
        #expect(room.link == .offline)
    }

    @Test func editMadeDuringASendSurvivesIt() {
        let sent = ACCommand(setpoint: 21)
        let pending = ACCommand(isOn: true, setpoint: 23)
        #expect(pending.removing(sent) == ACCommand(isOn: true, setpoint: 23))
        #expect(ACCommand(setpoint: 21).removing(sent).isEmpty)
    }

    @Test func homeSkipsDevicesWithoutAValidKeyAndTracksAnyOn() async {
        let home = Home(schedule: .init(active: .seconds(60), idle: .seconds(60))) { config in
            config.deviceKey == nil ? nil : FakeDevice(ACState(isOn: config.name == "On", mode: .cool, setpoint: 20, fan: .auto))
        }
        home.configure([
            DeviceConfig(name: "On", host: "a.local", key: "AAECAwQFBgcICQoLDA0ODw=="),
            DeviceConfig(name: "Off", host: "b.local", key: "AAECAwQFBgcICQoLDA0ODw=="),
            DeviceConfig(name: "Broken", host: "c.local", key: "nope"),
        ])
        home.stop()
        #expect(home.rooms.map(\.name) == ["On", "Off"])
        #expect(home.selectedRoom?.name == "On")
        await home.refreshAll()
        #expect(home.anyOn)
    }

    @Test func registryRoundTripsThroughAStore() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "aircon-\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let registry = DeviceRegistry(store: FileBlobStore(url: url))
        #expect(try registry.load().isEmpty)
        let devices = [DeviceConfig(name: "Suite", host: "DAIKIN4C5D6E.local", key: "AAECAwQFBgcICQoLDA0ODw==")]
        try registry.save(devices)
        #expect(try registry.load() == devices)
    }
}

struct DeviceConfigTests {
    @Test func handWrittenFilesMayOmitTheID() throws {
        let json = #"[{"name":"Sala","host":"DAIKIN7D8E9F.local","key":"AAECAwQFBgcICQoLDA0ODw=="}]"#
        let devices = try JSONDecoder().decode([DeviceConfig].self, from: Data(json.utf8))
        #expect(devices.first?.name == "Sala")
        #expect(devices.first?.deviceKey != nil)
    }
}

@MainActor
struct VoiceCommandTests {
    let off = ACState(isOn: false, mode: .cool, setpoint: 20, fan: .auto, roomTemperature: 23)

    @Test func sendAppliesAtOnceAndReturnsTheReportedState() async throws {
        let device = FakeDevice(off)
        let room = Room(id: UUID(), name: "Living", device: device, debounce: .seconds(60))
        let state = try await room.send { $0.isOn = true; $0.setpoint = 22 }
        #expect(state.isOn && state.setpoint == 22)
        #expect(device.commands == [ACCommand(isOn: true, setpoint: 22)])
        #expect(room.pending.isEmpty)
    }

    @Test func sendThrowsWhenTheUnitIsUnreachable() async {
        let device = FakeDevice(off)
        device.setFailing(true)
        let room = Room(id: UUID(), name: "Living", device: device)
        await #expect(throws: RoomError.unreachable("Living")) { try await room.send { $0.isOn = true } }
        #expect(room.state == nil)
    }

    @Test func currentStateRefreshes() async throws {
        let device = FakeDevice(off)
        let room = Room(id: UUID(), name: "Living", device: device)
        device.setState(off.applying(ACCommand(isOn: true)))
        #expect(try await room.currentState().isOn)
    }

    @Test func turnOffAllSkipsUnitsAlreadyOffAndReportsFailures() async {
        let on = ACState(isOn: true, mode: .cool, setpoint: 20, fan: .auto)
        let devices = ["A": FakeDevice(on), "B": FakeDevice(off), "C": FakeDevice(on)]
        devices["C"]!.setFailing(true)
        let home = Home(schedule: .init(active: .seconds(60), idle: .seconds(60))) { devices[$0.name] }
        home.configure(["A", "B", "C"].map { DeviceConfig(name: $0, host: "\($0).local", key: "") })
        home.stop()

        let result = await home.turnOffAll()
        #expect(result.turnedOff.map(\.name) == ["A"])
        #expect(result.unreachable.map(\.name) == ["C"])
        #expect(devices["A"]!.current.isOn == false)
        #expect(devices["B"]!.commands.isEmpty)
    }
}
