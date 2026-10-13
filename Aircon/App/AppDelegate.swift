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

        let home = Home(makeDevice: options.makeDevice)
        let library = DeviceLibrary(registry: options.makeRegistry(), home: home)
        library.load()
        home.selectedID = home.rooms.first { $0.name == options.initialRoom }?.id ?? home.selectedID

        let panelState = PanelState()
        let panel = PanelController(state: panelState, content: PanelRoot(home: home, library: library, panel: panelState))
        panel.onVisibilityChange = { home.isActive = $0 }
        let statusItem = StatusItemController(home: home) { panel.toggle(from: $0) }

        if let screen = options.initialScreen {
            panelState.screen = screen
            panel.show(from: statusItem.button)
        }
        self.home = home
        self.panel = panel
        self.statusItem = statusItem
    }

    func applicationWillTerminate(_ notification: Notification) {
        home?.stop()
    }
}
