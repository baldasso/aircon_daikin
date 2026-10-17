import XCTest

/// The ways to change the temperature without dragging, on the demo's living room (cooling at 21°).
@MainActor
final class SetpointInteractionTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        app = XCUIApplication()
        app.launchEnvironment = ["AIRCON_DEMO": "1", "AIRCON_SHOW": "controls"]
        app.launchArguments = ["-AppleLanguages", "(en)"]
        var opened = false
        for _ in 1...2 where !opened {
            app.launch()
            opened = app.windows.firstMatch.waitForExistence(timeout: 10)
        }
        XCTAssertTrue(opened, "The panel didn't open")
    }

    override func tearDown() {
        app.terminate()
    }

    private var hero: XCUIElement { app.sliders.firstMatch }

    private var setpoint: Int? {
        (hero.value as? NSNumber)?.intValue
    }

    // Which way a synthetic scroll goes depends on the Mac's natural scrolling setting, so these only
    // check that scrolling moves the setpoint, reverses, and stops at the end of the range. 18 pt is a degree.
    func testScrollingMovesTheSetpoint() {
        XCTAssertEqual(setpoint, 21)
        hero.scroll(byDeltaX: 0, deltaY: 40)
        let moved = expectation(for: NSPredicate { _, _ in self.setpoint != 21 }, evaluatedWith: nil)
        wait(for: [moved], timeout: 3)
    }

    func testScrollingStopsAtTheEndAndReverses() {
        for _ in 0..<12 { hero.scroll(byDeltaX: 0, deltaY: 40) }
        let end = expectation(for: NSPredicate { _, _ in [16, 32].contains(self.setpoint) }, evaluatedWith: nil)
        wait(for: [end], timeout: 5)
        let limit = setpoint
        hero.scroll(byDeltaX: 0, deltaY: 40)
        XCTAssertEqual(setpoint, limit, "Scrolling past the end moved it")
        hero.scroll(byDeltaX: 0, deltaY: -40)
        let back = expectation(for: NSPredicate { _, _ in self.setpoint != limit }, evaluatedWith: nil)
        wait(for: [back], timeout: 3)
    }

    func testArrowKeysStepOneDegree() {
        app.typeKey(.upArrow, modifierFlags: [])
        let up = expectation(for: NSPredicate { _, _ in self.setpoint == 22 }, evaluatedWith: nil)
        wait(for: [up], timeout: 3)
        app.typeKey(.downArrow, modifierFlags: [])
        app.typeKey(.downArrow, modifierFlags: [])
        let down = expectation(for: NSPredicate { _, _ in self.setpoint == 20 }, evaluatedWith: nil)
        wait(for: [down], timeout: 3)
    }
}
