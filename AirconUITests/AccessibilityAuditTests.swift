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
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10), "The panel didn't open")
        try app.performAccessibilityAudit()
        app.terminate()
    }
}
