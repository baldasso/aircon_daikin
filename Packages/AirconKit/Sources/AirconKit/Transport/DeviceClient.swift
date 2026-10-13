import Foundation

/// Anything that can report and change an air conditioner's state. The app talks only to this.
public protocol ACDevice: Sendable {
    func fetchState() async throws -> ACState
    func apply(_ command: ACCommand) async throws -> ACState
}

/// Talks to a Daikin Smart AC (Brazil) unit over the local network.
public struct DeviceClient: ACDevice {
    public static let port: UInt16 = 15914

    private let http: RawHTTP
    private let key: DeviceKey

    public init(host: String, key: DeviceKey) {
        http = RawHTTP(host: host, port: Self.port)
        self.key = key
    }

    public func fetchState() async throws -> ACState {
        try decode(await http.send(.get, "/acstatus"))
    }

    public func apply(_ command: ACCommand) async throws -> ACState {
        let body = try Frame.seal(command.wirePayload(), key: key)
        return try decode(await http.send(.post, "/acstatus", body: body))
    }

    private func decode(_ body: String) throws -> ACState {
        try ACState(wire: Frame.open(body, key: key))
    }
}
