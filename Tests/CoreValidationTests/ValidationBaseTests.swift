@testable import CoreValidation
import NonEmpty
import XCTest

@MainActor
final class ValidationBaseTests: XCTestCase {
	func test() {
		@ValidationBase({ $input in
			if $input.oldValues.isEmpty { "Must be set" }
			if input.isEmpty { "Cannot be empty" }
			if input.isBlank { "Cannot be blank" }
		})
		var sut = ""
		XCTAssertEqual(sut, nil)
		XCTAssertEqual($sut.errors, NonEmptyArray("Must be set", "Cannot be empty", "Cannot be blank"))

		sut = ""
		XCTAssertEqual(sut, nil)
		XCTAssertEqual($sut.errors, NonEmptyArray("Cannot be empty", "Cannot be blank"))

		sut = " "
		XCTAssertEqual(sut, nil)
		XCTAssertEqual($sut.errors, NonEmptyArray("Cannot be blank"))

		sut = "  "
		XCTAssertEqual(sut, nil)
		XCTAssertEqual($sut.errors, NonEmptyArray("Cannot be blank"))

		sut = "Some value"
		XCTAssertEqual(sut, "Some value")
		XCTAssertEqual($sut.errors, nil)
	}
}
