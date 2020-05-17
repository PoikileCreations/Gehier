import XCTest
@testable import Gehier

final class GehierTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Gehier().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
