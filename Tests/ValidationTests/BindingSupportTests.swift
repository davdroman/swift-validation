#if canImport(SwiftUI)
import Validation
import SwiftUI
import XCTest

final class ValidationExtraTests: XCTestCase {
	func testBinding() {
		var validation = Validation<String, String> { input in
			switch input {
			case nil: "Cannot be nil"
			case let input?:
				if input.isEmpty { "Cannot be empty" }
				if input.isBlank { "Cannot be blank" }
			}
		}

		let sut = Binding(
			validating: Binding(
				get: { validation },
				set: { validation = $0 }
			),
			default: ""
		)
		XCTAssertEqual(sut.wrappedValue, "")
		XCTAssertEqual(validation.errors, NonEmptyArray("Cannot be nil"))

		sut.wrappedValue = ""
		XCTAssertEqual(sut.wrappedValue, "")
		XCTAssertEqual(validation.errors, NonEmptyArray("Cannot be empty", "Cannot be blank"))

		sut.wrappedValue = " "
		XCTAssertEqual(sut.wrappedValue, " ")
		XCTAssertEqual(validation.errors, NonEmptyArray("Cannot be blank"))

		sut.wrappedValue = "  "
		XCTAssertEqual(sut.wrappedValue, "  ")
		XCTAssertEqual(validation.errors, NonEmptyArray("Cannot be blank"))
	}
}
#endif
