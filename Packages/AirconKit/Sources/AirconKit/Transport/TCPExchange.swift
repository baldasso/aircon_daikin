import Foundation
import Network
import Synchronization

/// One request/response over a fresh TCP connection. The firmware closes the socket after answering,
/// so the response is everything received until EOF.
final class TCPExchange: Sendable {
    private static let queue = DispatchQueue(label: "dev.baldasso.aircon.tcp")

    private let connection: NWConnection
    private let request: Data
    private let state = Mutex(State())

    private struct State {
        var continuation: CheckedContinuation<Data, Error>?
        var received = Data()
        var finished = false
    }

    init(host: String, port: UInt16, request: Data) {
        connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: .tcp)
        self.request = request
    }

    func run(timeout: TimeInterval) async throws -> Data {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                state.withLock { $0.continuation = continuation }
                connection.stateUpdateHandler = { [self] in handle($0) }
                connection.start(queue: Self.queue)
                Self.queue.asyncAfter(deadline: .now() + timeout) { [self] in finish(.failure(AirconError.timeout)) }
            }
        } onCancel: {
            finish(.failure(CancellationError()))
        }
    }

    private func handle(_ connectionState: NWConnection.State) {
        switch connectionState {
        case .ready:
            connection.send(content: request, completion: .contentProcessed { [self] error in
                if let error { finish(.failure(error)) }
            })
            receive()
        case .waiting(let error), .failed(let error):
            finish(.failure(error))
        default:
            break
        }
    }

    private func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [self] data, _, isComplete, error in
            let received = state.withLock { state in
                if let data { state.received.append(data) }
                return state.received
            }
            if isComplete || error != nil {
                finish(received.isEmpty ? .failure(error ?? AirconError.malformedFrame) : .success(received))
            } else {
                receive()
            }
        }
    }

    private func finish(_ result: Result<Data, Error>) {
        let continuation = state.withLock { state -> CheckedContinuation<Data, Error>? in
            guard !state.finished else { return nil }
            state.finished = true
            defer { state.continuation = nil }
            return state.continuation
        }
        guard let continuation else { return }
        connection.cancel()
        continuation.resume(with: result)
    }
}
