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
//		@Validation(mode: .automatic(delay: .seconds(0.25)) | .manual, { past, new, error in // ❌ "past" could mean history, but it's still a long shot
//		@Validation(mode: .automatic(delay: .seconds(0.25)) | .manual, { pastValues, newValue, error in // ❌ "past" is longer than "old"
//		@Validation(mode: .automatic(delay: .seconds(0.25)) | .manual, { oldValues, newValue, error in // ✅ most similar to SwiftUI APIs (e.g. .onChange)
//			guard let new else { error("Name cannot be nil"); return }
//			if new.isBlank { error("Name cannot be blank") }
//			if new.count < 2 { error("Name cannot be shorter than 2 characters") }
//			if new.rangeOfCharacter(from: .symbols) != nil { error("Name cannot contain special characters or symbols") }
//		})
//		var input: String? = nil

//		$input.validate()

//		@TaskLocal enclosingInstance: Any?
//		@Get(\Self.name) var name // reads from $enclosingInstance
//		@Property(\Self.name) var name // reads from $enclosingInstance
//		@Get(\Self.name) var name // reads from $enclosingInstance

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
