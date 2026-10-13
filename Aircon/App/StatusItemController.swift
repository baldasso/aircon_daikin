import AirconKit
import AppKit
import Observation

/// The menu bar icon. It fills in while any unit is running.
@MainActor
final class StatusItemController: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let home: Home
    private let onClick: (NSStatusBarButton) -> Void

    var button: NSStatusBarButton? { item.button }

    init(home: Home, onClick: @escaping (NSStatusBarButton) -> Void) {
        self.home = home
        self.onClick = onClick
        super.init()
        item.button?.target = self
        item.button?.action = #selector(clicked)
        item.button?.setAccessibilityLabel("Aircon")
        trackIcon()
    }

    @objc private func clicked() {
        if let button = item.button { onClick(button) }
    }

    private func trackIcon() {
        let anyOn = withObservationTracking { home.anyOn } onChange: { [weak self] in
            Task { @MainActor in self?.trackIcon() }
        }
        let symbol = anyOn ? "air.conditioner.horizontal.fill" : "air.conditioner.horizontal"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Aircon")
        image?.isTemplate = true
        item.button?.image = image
    }
}
