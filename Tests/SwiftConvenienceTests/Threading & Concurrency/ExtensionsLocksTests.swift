import SwiftConvenience
import SwiftConvenienceTestUtils

import Foundation
import XCTest

class ExtensionsLocksTests: XCTestCase {
    func test_os_unfair_lock() throws {
        var lock = os_unfair_lock()
        let count = 1000
        let expFinished = expectation(description: "finished")
        expFinished.expectedFulfillmentCount = count
        var sum = 0
        for i in 0..<count {
            DispatchQueue.global().async {
                lock.withLock {
                    sum += i
                }
                expFinished.fulfill()
            }
        }
        
        waitForExpectations()
        XCTAssertEqual(sum, (0..<count).reduce(0, +))
    }
}
