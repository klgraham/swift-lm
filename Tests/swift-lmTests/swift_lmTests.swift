import XCTest
@testable import swift_lm

class swift_lmTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(swift_lm().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
