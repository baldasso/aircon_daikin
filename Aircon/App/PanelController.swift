import AppKit
import Observation
import SwiftUI

/// What the panel is showing and whether it is on screen. Views read this; only the controller writes `isVisible`.
@MainActor @Observable
final class PanelState {
    enum Screen: String {
        case controls, settings
    }

    var screen = Screen.controls
    /// A unit to start adding when settings open (from discovery or a launch switch).
    var addingHost: String?
    fileprivate(set) var isVisible = false
}

/// A borderless panel that drops down from the status item and goes away when it loses focus.
@MainActor
final class PanelController: NSObject, NSWindowDelegate {
    static let size = CGSize(width: 340, height: 572)

    var onVisibilityChange: ((Bool) -> Void)?
    /// Sees key presses while the panel is open; returns true to swallow one.
    var onKeyDown: ((NSEvent) -> Bool)?

    private let panel = FloatingPanel(size: PanelController.size)
    private let state: PanelState
    private var hiddenAt = Date.distantPast
    private var keyMonitor: Any?

    init(state: PanelState, content: some View) {
        self.state = state
        super.init()
        let host = NSHostingView(rootView: content)
        host.frame = NSRect(origin: .zero, size: Self.size)
        panel.contentView = host
        panel.delegate = self
        panel.onCancel = { [weak self] in self?.hide() }
    }

    func toggle(from button: NSStatusBarButton) {
        if panel.isVisible {
            hide()
        } else if Date().timeIntervalSince(hiddenAt) > 0.3 {
            // A click on the icon while open first resigns the panel (hiding it); don't reopen on the same click.
            show(from: button)
        }
    }

    func show(from button: NSStatusBarButton?) {
        position(below: button)
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        setVisible(true)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            panel.animator().alphaValue = 1
        }
    }

    func hide() {
        guard state.isVisible else { return }
        hiddenAt = Date()
        setVisible(false)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                guard let self, !self.state.isVisible else { return }
                self.panel.orderOut(nil)
                self.state.screen = .controls
            }
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }

    private func setVisible(_ visible: Bool) {
        state.isVisible = visible
        onVisibilityChange?(visible)
        watchKeys(visible)
    }

    /// A local monitor only while open, so nothing listens to the keyboard the rest of the time.
    private func watchKeys(_ visible: Bool) {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
        guard visible else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            nonisolated(unsafe) let event = event
            let used = MainActor.assumeIsolated {
                guard let self, event.window === self.panel else { return false }
                return self.onKeyDown?(event) == true
            }
            return used ? nil : event
        }
    }

    private func position(below button: NSStatusBarButton?) {
        let screen = button?.window?.screen ?? NSScreen.main
        guard let bounds = screen?.visibleFrame else { return panel.center() }
        // Right after launch the status item may not be placed yet; fall back to the top-right corner.
        let anchor = (button?.window?.frame).flatMap { $0.minY >= bounds.maxY - 2 ? $0 : nil }
            ?? NSRect(x: bounds.maxX - Self.size.width / 2 - 8, y: bounds.maxY, width: 0, height: 0)
        let x = min(max(anchor.midX - Self.size.width / 2, bounds.minX + 8), bounds.maxX - Self.size.width - 8)
        panel.setFrameOrigin(NSPoint(x: x, y: min(anchor.minY, bounds.maxY) - Self.size.height - 6))
    }
}

final class FloatingPanel: NSPanel {
    var onCancel: (() -> Void)?

    init(size: CGSize) {
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        isFloatingPanel = true
        level = .statusBar
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        isMovable = false
        hidesOnDeactivate = false
        animationBehavior = .none
        appearance = NSAppearance(named: .darkAqua)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        // Borderless, so the title is never drawn; VoiceOver announces it, and a floating window
        // reads better than the "system dialog" a non-activating panel gets by default.
        title = "Aircon"
        setAccessibilitySubrole(.floatingWindow)
    }

    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}
