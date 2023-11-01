@testable import CoreValidation
import NonEmpty
import XCTest

@MainActor
final class ValidationBaseTests: XCTestCase {
	func test() {
		let sut = ValidationBase(wrappedValue: "") { (input: String?) in
			switch input {
			case nil: "Cannot be nil"
			case let input?:
				if input.isEmpty { "Cannot be empty" }
				if input.isBlank { "Cannot be blank" }
			}
		}

		XCTAssertEqual(sut.errors, NonEmptyArray("Cannot be empty", "Cannot be blank"))

		sut.wrappedValue = ""
		XCTAssertEqual(sut.errors, NonEmptyArray("Cannot be empty", "Cannot be blank"))

		sut.wrappedValue = " "
		XCTAssertEqual(sut.errors, NonEmptyArray("Cannot be blank"))

		sut.wrappedValue = "  "
		XCTAssertEqual(sut.errors, NonEmptyArray("Cannot be blank"))
	}
}
