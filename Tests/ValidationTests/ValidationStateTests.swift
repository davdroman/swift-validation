@testable import Validation
import XCTest

final class ValidationStateTests: XCTestCase {
	func testDynamicMemberLookup() throws {
		let sut = _ValidationState<String, String>(rawValue: "", phase: .idle)
		XCTAssert(sut.isIdle == true)
	}
}
