import Foundation

/// Checks a key against a unit before it is saved, forgiving the usual copying mistakes.
///
/// Keys are read off a phone screen and often typed by hand, so look-alike characters get swapped
/// (I, l and 1; O and 0). One status frame is fetched from the unit and every look-alike variant of the
/// typed key is tried on it locally: the variant that decrypts to a valid state is the real key.
public enum KeyCheck {
    public enum Outcome: Equatable, Sendable {
        /// `key` may differ from what was typed if a look-alike was corrected.
        case valid(key: String, state: ACState)
        case wrongKey
        case unreachable
    }

    private static let lookAlikes: [Character: [Character]] = [
        "I": ["I", "l", "1"], "l": ["l", "I", "1"], "1": ["1", "l", "I"],
        "O": ["O", "0"], "0": ["0", "O"],
    ]

    /// Enough for a key with a handful of ambiguous characters; past that, only the typed key is tried.
    static let maxCandidates = 2048

    public static func run(_ typed: String, host: String) async -> Outcome {
        do {
            let frame = try await RawHTTP(host: host, port: DeviceClient.port).send(.get, "/acstatus")
            return check(typed, against: frame)
        } catch {
            return .unreachable
        }
    }

    static func check(_ typed: String, against frame: String) -> Outcome {
        for candidate in candidates(for: typed) {
            guard let key = DeviceKey(base64: candidate),
                  let plaintext = try? Frame.open(frame, key: key),
                  let state = try? ACState(wire: plaintext) else { continue }
            return .valid(key: candidate, state: state)
        }
        return .wrongKey
    }

    /// The typed key first, then its look-alike variants.
    static func candidates(for typed: String) -> [String] {
        let cleaned = typed.filter { !$0.isWhitespace }
        let options = cleaned.map { lookAlikes[$0] ?? [$0] }
        let total = options.reduce(1) { $0 * $1.count }
        guard total <= maxCandidates else { return [cleaned] }

        var results = [""]
        for choices in options {
            results = results.flatMap { prefix in choices.map { prefix + String($0) } }
        }
        return results
    }
}
