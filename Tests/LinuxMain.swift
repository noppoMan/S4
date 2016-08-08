#if os(Linux)

import XCTest
@testable import S4Tests

XCTMain([
    testCase(ExampleTests.allTests),
    testCase(BodyTests.allTests),
    testCase(RequestTests.allTests)
])

#endif
