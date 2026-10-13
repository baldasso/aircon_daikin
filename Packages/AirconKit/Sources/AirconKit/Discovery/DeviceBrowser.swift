import Foundation
import Network
import Observation

/// A unit announcing itself over Bonjour (`_iota._tcp`).
public struct DiscoveredDevice: Hashable, Identifiable, Sendable {
    /// The name the Daikin app shows as the unit's SSID, e.g. `DAIKINA1B2C3`. It is also its hostname.
    public let id: String
    public var host: String { "\(id).local" }

    /// The TXT record's `apn` is the MAC address; its first three bytes, reversed, make the hostname:
    /// `DAIKIN:C3B2A1DDEEFF` → `DAIKINA1B2C3`.
    public init?(apn: String) {
        let hex = apn.replacingOccurrences(of: "DAIKIN:", with: "")
        guard hex.count >= 6 else { return nil }
        let pairs = stride(from: 0, to: 6, by: 2).map { offset in
            let start = hex.index(hex.startIndex, offsetBy: offset)
            return String(hex[start..<hex.index(start, offsetBy: 2)])
        }
        id = "DAIKIN" + pairs.reversed().joined()
    }
}

/// Lists units on the local network while started. Stop it when the UI that shows them goes away.
@MainActor @Observable
public final class DeviceBrowser {
    public private(set) var found: [DiscoveredDevice] = []
    private var browser: NWBrowser?

    public init() {}

    public func start() {
        guard browser == nil else { return }
        let browser = NWBrowser(for: .bonjourWithTXTRecord(type: "_iota._tcp", domain: nil), using: .tcp)
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            let devices = Self.devices(in: results)
            MainActor.assumeIsolated { self?.found = devices }
        }
        browser.start(queue: .main)
        self.browser = browser
    }

    public func stop() {
        browser?.cancel()
        browser = nil
    }

    private nonisolated static func devices(in results: Set<NWBrowser.Result>) -> [DiscoveredDevice] {
        let devices = results.compactMap { result -> DiscoveredDevice? in
            guard case .bonjour(let record) = result.metadata, let apn = record["apn"] else { return nil }
            return DiscoveredDevice(apn: apn)
        }
        return Set(devices).sorted { $0.id < $1.id }
    }
}
