import Foundation

/// Minimal HTTP/1.1. The firmware sends tab-indented header lines that URLSession won't parse.
struct RawHTTP: Sendable {
    enum Method: String, Sendable {
        case get = "GET", post = "POST"
    }

    let host: String
    let port: UInt16
    var timeout: TimeInterval = 6

    func send(_ method: Method, _ path: String, body: String = "") async throws -> String {
        let request = "\(method.rawValue) \(path) HTTP/1.1\r\nHost: \(host)\r\n"
            + "Content-Length: \(body.utf8.count)\r\n\r\n\(body)"
        let exchange = TCPExchange(host: host, port: port, request: Data(request.utf8))
        return try Self.body(of: await exchange.run(timeout: timeout))
    }

    static func body(of response: Data) throws -> String {
        guard let text = String(data: response, encoding: .utf8),
              let separator = text.range(of: "\r\n\r\n") else {
            throw AirconError.unexpectedResponse("no HTTP body")
        }
        let statusLine = String(text[..<separator.lowerBound].prefix { $0 != "\r" })
        guard statusLine.contains(" 200") else { throw AirconError.unexpectedResponse(statusLine) }
        return String(text[separator.upperBound...])
    }
}
