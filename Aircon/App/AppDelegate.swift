import AirconKit
import AppKit

/// Wires the pieces together. Nothing else knows about more than one of them.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: StatusItemController?
    private var panel: PanelController?
    private var home: Home?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let options = LaunchOptions()
        if let importFile = options.importFile {
            Importer.run(file: importFile, into: options.makeRegistry())
            NSApp.terminate(nil)
            return
        }

        let home = Home(makeDevice: LaunchOptions.makeDevice)
        let library = DeviceLibrary(registry: options.makeRegistry(), home: home)
        let panelState = PanelState()
        let panel = PanelController(state: panelState, content: PanelRoot(home: home, library: library, panel: panelState))
        panel.onVisibilityChange = { home.isActive = $0 }
        let statusItem = StatusItemController(home: home) { panel.toggle(from: $0) }
        self.home = home
        self.panel = panel
        self.statusItem = statusItem

        // The icon goes up first: reading the keychain can wait on the user approving access.
        DispatchQueue.main.async {
            library.load()
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
        home?.stop()
    }
}
