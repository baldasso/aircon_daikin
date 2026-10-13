import AirconKit
import AppIntents
import AppKit

/// Wires the pieces together. Nothing else knows about more than one of them.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let options = LaunchOptions()
    private let home = Home(makeDevice: LaunchOptions.makeDevice)
    private lazy var library = DeviceLibrary(registry: options.makeRegistry(), home: home)
    private var statusItem: StatusItemController?
    private var panel: PanelController?

    override init() {
        super.init()
        // Siri may launch the app to run an intent; the intents need these before launch finishes.
        IntentContext.home = home
        IntentContext.library = library
        library.onRoomsChange = { AirconShortcuts.updateAppShortcutParameters() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let importFile = options.importFile {
            Importer.run(file: importFile, into: options.makeRegistry())
            NSApp.terminate(nil)
            return
        }

        let home = home
        let library = library
        let options = options
        #if DEBUG
        if ProcessInfo.processInfo.environment["AIRCON_INTENT_SELFTEST"] == "1" {
            Task { await IntentSelfTest.run(home: home, library: library) }
            return
        }
        #endif
        let panelState = PanelState()
        let panel = PanelController(state: panelState, content: PanelRoot(home: home, library: library, panel: panelState))
        panel.onVisibilityChange = { home.isActive = $0 }
        let statusItem = StatusItemController(home: home) { panel.toggle(from: $0) }
        self.panel = panel
        self.statusItem = statusItem

        // The icon goes up first: reading the keychain can wait on the user approving access.
        DispatchQueue.main.async {
            library.loadIfNeeded()
            if options.startsInDemo { library.startDemo() }
            home.selectedID = home.rooms.first { $0.name == options.initialRoom }?.id ?? home.selectedID
            panelState.addingHost = options.addingHost
            if let screen = options.initialScreen {
                panelState.screen = screen
                panel.show(from: statusItem.button)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        home.stop()
    }
}
