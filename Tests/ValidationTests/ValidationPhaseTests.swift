@testable import Validation
import XCTest

final class ValidationPhaseTests: XCTestCase {
	func testComputedProperties_idle() throws {
		let sut = ValidationPhase<String, String>.idle

		XCTAssert(sut.isIdle == true)
		XCTAssert(sut.isValidating == false)
		XCTAssert(sut.isInvalid == false)
		XCTAssert(sut.isValid == false)

		XCTAssert(sut.errors == nil)
		XCTAssert(sut.value == nil)
	}

	func testComputedProperties_validating() throws {
		let sut = ValidationPhase<String, String>.validating(nil)

		XCTAssert(sut.isIdle == false)
		XCTAssert(sut.isValidating == true)
		XCTAssert(sut.isInvalid == false)
		XCTAssert(sut.isValid == false)

		XCTAssert(sut.errors == nil)
		XCTAssert(sut.value == nil)
	}

	func testComputedProperties_invalid() throws {
		let sut = ValidationPhase<String, String>.invalid(["error"])

		XCTAssert(sut.isIdle == false)
		XCTAssert(sut.isValidating == false)
		XCTAssert(sut.isInvalid == true)
		XCTAssert(sut.isValid == false)

		XCTAssert(sut.errors == ["error"])
		XCTAssert(sut.value == nil)
	}

	func testComputedProperties_valid() throws {
		let sut = ValidationPhase<String, String>.valid("value")

		XCTAssert(sut.isIdle == false)
		XCTAssert(sut.isValidating == false)
		XCTAssert(sut.isInvalid == false)
		XCTAssert(sut.isValid == true)

		XCTAssert(sut.errors == nil)
		XCTAssert(sut.value == "value")
	}
}
