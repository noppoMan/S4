import XCTest
@testable import S4

class RequestTests: XCTestCase {
    func testReality() {
        XCTAssert(2 + 2 == 4, "Something is severely wrong here.")
    }
}

extension RequestTests {
    static var allTests: [(String, (RequestTests) -> () throws -> Void)] {
        return [
            ("testReality", testReality),
        ]
    }
}
