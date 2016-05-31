import XCTest
@testable import S4

class RequestTests: XCTestCase {
    static var allTests : [(String, (RequestTests) -> () throws -> Void)] {
        return [
               ("testCookies", testCookies),
        ]
    }

    func testCookies() {
        let request = Request(headers: ["Cookie": "test=123;other-cookie=321"])

        XCTAssert(request.cookies["test"] == "123", "Cookies did not parse")
        XCTAssert(request.cookies["other-cookie"] == "321", "Cookies did not parse")
    }
    
}
