@testable import CoreValidation
import NonEmpty
import XCTest

@MainActor
final class ValidationBaseTests: XCTestCase {
	func test() {
		@ValidationBase<String, String?>({ $input in
			if $input.isUnset { nil }
			if input.isEmpty { "Cannot be empty" }
			if input.isBlank { "Cannot be blank" }
		})
		var sut = ""
		XCTAssertEqual(sut, nil)
		XCTAssertEqual($sut.errors, NonEmptyArray(nil, "Cannot be empty", "Cannot be blank"))

		sut = ""
		XCTAssertEqual(sut, nil)
		XCTAssertEqual($sut.errors, NonEmptyArray(nil, "Cannot be empty", "Cannot be blank"))

		sut = " "
		XCTAssertEqual(sut, nil)
		XCTAssertEqual($sut.errors, NonEmptyArray("Cannot be blank"))

		sut = ""
		XCTAssertEqual(sut, nil)
		XCTAssertEqual($sut.errors, NonEmptyArray("Cannot be empty", "Cannot be blank"))

		sut = " "
		XCTAssertEqual(sut, nil)
		XCTAssertEqual($sut.errors, NonEmptyArray("Cannot be blank"))

		sut = " S"
		XCTAssertEqual(sut, " S")
		XCTAssertEqual($sut.errors, nil)
	}
}
