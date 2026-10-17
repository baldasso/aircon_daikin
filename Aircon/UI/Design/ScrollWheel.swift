import AppKit
import SwiftUI

extension View {
    /// Scroll-wheel and two-finger scroll over this view, which SwiftUI only offers inside a scroll view.
    /// The event is consumed when it lands here, and passed on everywhere else.
    func onScrollWheel(perform action: @escaping (NSEvent) -> Void) -> some View {
        background(ScrollWheelReader(action: action))
    }
}

private struct ScrollWheelReader: NSViewRepresentable {
    let action: (NSEvent) -> Void

    func makeNSView(context: Context) -> ScrollWheelView {
        ScrollWheelView()
    }

    func updateNSView(_ view: ScrollWheelView, context: Context) {
        view.action = action
    }
}

/// Watches scroll events only while it is in a window, and never takes clicks: it sits behind the view.
private final class ScrollWheelView: NSView {
    var action: ((NSEvent) -> Void)?
    private var monitor: Any?

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        guard window != nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            nonisolated(unsafe) let event = event
            let used = MainActor.assumeIsolated {
                guard let self, let window = self.window, event.window === window,
                      self.bounds.contains(self.convert(event.locationInWindow, from: nil)) else { return false }
                self.action?(event)
                return true
            }
            return used ? nil : event
        }
    }
}
