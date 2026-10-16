import AirconKit
import AppKit
import Observation

/// The menu bar icon. It fills in while any unit is running, and bounces once when one starts or stops,
/// whether from the panel, Siri or Shortcuts.
@MainActor
final class StatusItemController: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let icon = NSImageView()
    private let home: Home
    private let onClick: (NSStatusBarButton) -> Void
    /// Last known power of each unit that has reported, to tell a real change from a first report.
    private var power: [UUID: Bool] = [:]

    var button: NSStatusBarButton? { item.button }

    init(home: Home, onClick: @escaping (NSStatusBarButton) -> Void) {
        self.home = home
        self.onClick = onClick
        super.init()
        guard let button = item.button else { return }
        button.target = self
        button.action = #selector(clicked)
        // The symbol lives in an image view, which can play symbol effects; the button can't.
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.imageScaling = .scaleProportionallyDown
        button.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])
        trackIcon()
    }

    @objc private func clicked() {
        if let button = item.button { onClick(button) }
    }

    private func trackIcon() {
        let current = withObservationTracking {
            Dictionary(uniqueKeysWithValues: home.rooms.compactMap { room in room.state.map { (room.id, $0.isOn) } })
        } onChange: { [weak self] in
            Task { @MainActor in self?.trackIcon() }
        }
        let changed = current.contains { id, isOn in power[id].map { $0 != isOn } ?? false }
        power = current

        let running = current.values.filter { $0 }.count
        let symbol = running > 0 ? "air.conditioner.horizontal.fill" : "air.conditioner.horizontal"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 14, weight: .regular))
        image?.isTemplate = true
        icon.image = image
        if changed && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            icon.addSymbolEffect(.bounce, options: .nonRepeating)
        }
        // VoiceOver hears how many units are running without opening the panel.
        item.button?.setAccessibilityLabel(String(localized: "Aircon, \(running) running", comment: "Menu bar icon; number of units on"))
    }
}
