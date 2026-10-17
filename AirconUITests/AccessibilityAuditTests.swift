import XCTest

/// Runs Apple's accessibility audit on each screen of the panel, with demo units, in both languages.
/// The audit checks labels, contrast, hit areas, clipped text and element traits.
@MainActor
final class AccessibilityAuditTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = true
    }

    func testControlsWithUnitOn() throws {
        try audit(["AIRCON_DEMO": "1", "AIRCON_SHOW": "controls"])
    }

    func testControlsWithUnitOff() throws {
        try audit(["AIRCON_DEMO": "1", "AIRCON_SHOW": "controls", "AIRCON_ROOM": "Bedroom"])
    }

    func testSettings() throws {
        try audit(["AIRCON_DEMO": "1", "AIRCON_SHOW": "settings"])
    }

    func testControlsInPortuguese() throws {
        try audit(["AIRCON_DEMO": "1", "AIRCON_SHOW": "controls"], language: "pt-BR")
    }

    private func audit(_ environment: [String: String], language: String = "en") throws {
        let app = XCUIApplication()
        app.launchEnvironment = environment
        app.launchArguments = ["-AppleLanguages", "(\(language))"]
        // The panel closes when another app takes focus, which can happen while the test launches it; one retry.
        var opened = false
        for _ in 1...2 where !opened {
            app.launch()
            opened = app.windows.firstMatch.waitForExistence(timeout: 10)
        }
        XCTAssertTrue(opened, "The panel didn't open")
        try app.performAccessibilityAudit { issue in
            // AppKit's own Touch Bar element, empty for an app without a Touch Bar; not part of the panel.
            if issue.element?.elementType == .touchBar { return true }
            let element = issue.element.map { "\($0.elementType.rawValue) label=\($0.label) value=\(String(describing: $0.value))" } ?? "none"
            print("AUDIT \(issue.compactDescription) | \(issue.detailedDescription) | \(element)")
            return false
        }
        app.terminate()
    }
}
