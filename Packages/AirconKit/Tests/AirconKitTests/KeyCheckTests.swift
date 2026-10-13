import Foundation
import Testing
@testable import AirconKit

struct KeyCheckTests {
    // The frame from ProtocolTests, sealed with key 000102…0f.
    let frame = "EBESExQVFhcYGRobHB0eH5V83J8bk6EyTKp1zGHh4/fhq6QPowk0b0FbQtv/k8BcGDUTP7FLqZwhQhdtmCw6JmgM0uXSe52TL4ah4fKmnaC8"
        + "HBxZjaT5HL06zGyUvJ2QLXdnlGUAhVZUZZqlkxuOJQX1LMC61J8hxWxRzAfpxsHD9kKEIKFOvygZauWpLIjWaCJGlLplQlMvUai33t9lv5HarxAgz/7X"
    let key = "AAECAwQFBgcICQoLDA0ODw=="

    @Test func acceptsTheExactKey() {
        guard case .valid(let found, let state) = KeyCheck.check(key, against: frame) else {
            Issue.record("expected a valid key")
            return
        }
        #expect(found == key)
        #expect(state.setpoint == 20)
    }

    @Test func correctsLookAlikesAndStraySpaces() {
        // The I typed as a lower-case L and the O as a zero, plus spaces from a sloppy copy.
        let typed = " AAECAwQFBgclCQoLDA00Dw== "
        #expect(KeyCheck.check(typed, against: frame) == KeyCheck.check(key, against: frame))
    }

    @Test func rejectsAKeyForAnotherUnit() {
        #expect(KeyCheck.check("ZmFrZWtleWZha2VrZXkxMg==", against: frame) == .wrongKey)
    }

    @Test func typedKeyIsTriedFirstAndVariantsAreBounded() {
        let candidates = KeyCheck.candidates(for: "I0")
        #expect(candidates.first == "I0")
        #expect(Set(candidates) == ["I0", "IO", "l0", "lO", "10", "1O"])
        #expect(KeyCheck.candidates(for: String(repeating: "I", count: 20)) == [String(repeating: "I", count: 20)])
    }

    @Test func unreachableHostIsReported() async {
        #expect(await KeyCheck.run(key, host: "aircon-test-no-such-host.invalid") == .unreachable)
    }

    @Test func coolingOnlyUnitsOfferNoHeat() {
        #expect(!Mode.offered(canHeat: false).contains(.heat))
        #expect(Mode.offered(canHeat: true).contains(.heat))
    }
}
