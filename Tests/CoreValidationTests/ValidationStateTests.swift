@testable import CoreValidation
import XCTest

final class ValidationStateTests: XCTestCase {
	func testDynamicMemberLookup() throws {
		let sut = ValidationState<String, String>(rawValue: "", phase: .idle)
		XCTAssert(sut.isIdle == true)
	}
}
