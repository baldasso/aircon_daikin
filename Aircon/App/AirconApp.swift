import SwiftUI

@main
struct AirconApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        // Everything lives in the status item's panel; this scene only satisfies `App`.
        Settings { EmptyView() }
    }
}
