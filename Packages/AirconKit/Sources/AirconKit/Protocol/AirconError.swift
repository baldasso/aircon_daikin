public enum AirconError: Error, Equatable, Sendable {
    case invalidKey
    case malformedFrame
    case checksumMismatch
    case cipherFailure
    case unexpectedResponse(String)
    case timeout
}
