import Builders
@testable import Validation
import XCTest

final class ValidationTests: XCTestCase {
	func testPropertyWrapper() throws {
		guard #available(iOS 17, macOS 14, tvOS 17, watchOS 9, *) else {
			throw XCTSkip()
		}

		@Validation({ input in
			switch input {
			case nil: "Input cannot be nil"
			case let input?:
				if input.isBlank { "Input cannot be blank" }
				if input.count < 2 { "Input cannot be shorter than 2 characters" }
				if input.rangeOfCharacter(from: .symbols) != nil { "Input cannot contain special characters or symbols" }
			}
		})
		var input: String? = nil

//		@Validation(mode: .live(delay: .seconds(0.25)) | .late, { ... ❌ - too ambiguous ("live" being vernacular in TCA, "late" is too much of an obscure UX term)
//		@Validation(mode: .asYouType(delay: .seconds(0.25)) | .onSubmit, { ... ❌ - should be agnostic (e.g. sliders)
//		@Validation(mode: .automatic(delay: .seconds(0.25)) | .manual, { ... ✅ best one so far
//
//		@Validation(mode: .automatic(delay: .seconds(0.25)) | .manual, { old, new, error in
//			guard let new else { error("Name cannot be nil"); return }
//			if new.isBlank { error("Name cannot be blank") }
//			if new.count < 2 { error("Name cannot be shorter than 2 characters") }
//			if new.rangeOfCharacter(from: .symbols) != nil { error("Name cannot contain special characters or symbols") }
//		})
//		var input: String? = nil

//		$input.validate()

		XCTAssertNil(input)
		XCTAssertEqual($input.errors, NonEmptyArray("Input cannot be nil"))

		input = ""
		XCTAssertNil(input)
		XCTAssertEqual($input.errors, NonEmptyArray(
			"Input cannot be blank",
			"Input cannot be shorter than 2 characters"
		))

		input = "D"
		XCTAssertNil(input)
		XCTAssertEqual($input.errors, NonEmptyArray(
			"Input cannot be shorter than 2 characters"
		))

		input = "Da"
		XCTAssertEqual(input, "Da")
		XCTAssertNil($input.errors)

		input = "David"
		XCTAssertEqual(input, "David")
		XCTAssertNil($input.errors)

		input = "David$"
		XCTAssertNil(input)
		XCTAssertEqual($input.errors, NonEmptyArray(
			"Input cannot contain special characters or symbols"
		))
	}
}
