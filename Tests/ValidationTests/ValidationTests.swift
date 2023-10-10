import Builders
@testable import Validation
import XCTest

final class ValidationTests: XCTestCase {
	func testPropertyWrapper() {
		struct InputState {
			@Validation(rules: { name in
				switch name {
				case nil: "Name cannot be nil"
				case let name?:
					if name.isBlank { "Name cannot be blank" }
					if name.count < 2 { "Name cannot be shorter than 2 characters" }
					if name.rangeOfCharacter(from: .symbols) != nil { "Name cannot contain special characters or symbols" }
				}
			})
			var name: String? = nil
		}

		var sut = InputState(name: nil)
		XCTAssertNil(sut.name)
		XCTAssertEqual(sut.$name.errors, NonEmptyArray("Name cannot be nil"))

		sut.name = ""
		XCTAssertNil(sut.name)
		XCTAssertEqual(sut.$name.errors, NonEmptyArray(
			"Name cannot be blank",
			"Name cannot be shorter than 2 characters"
		))

		sut.name = "D"
		XCTAssertNil(sut.name)
		XCTAssertEqual(sut.$name.errors, NonEmptyArray(
			"Name cannot be shorter than 2 characters"
		))

		sut.name = "Da"
		XCTAssertEqual(sut.name, "Da")
		XCTAssertNil(sut.$name.errors)

		sut.name = "David"
		XCTAssertEqual(sut.name, "David")
		XCTAssertNil(sut.$name.errors)

		sut.name = "David$"
		XCTAssertNil(sut.name)
		XCTAssertEqual(sut.$name.errors, NonEmptyArray(
			"Name cannot contain special characters or symbols"
		))
	}
}
