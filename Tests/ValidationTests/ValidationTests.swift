import Builders
@testable import Validation
import XCTest

final class ValidationTests: XCTestCase {
	func testPropertyWrapper() throws {
		guard #available(iOS 17, macOS 14, tvOS 17, watchOS 9, *) else {
			throw XCTSkip()
		}

		@Validation({ name in
			switch name {
			case nil: "Input cannot be nil"
			case let name?:
				if name.isBlank { "Input cannot be blank" }
				if name.count < 2 { "Input cannot be shorter than 2 characters" }
				if name.rangeOfCharacter(from: .symbols) != nil { "Input cannot contain special characters or symbols" }
			}
		})
		var sut: String? = nil

//		@Validation(mode: .live(delay: .seconds(0.25)) | .late, { ... ❌ - too ambiguous ("live" being vernacular in TCA, "late" is too much of an obscure UX term)
//		@Validation(mode: .asYouType(delay: .seconds(0.25)) | .onSubmit, { ... ❌ - should be agnostic (e.g. sliders)
//		@Validation(mode: .automatic(delay: .seconds(0.25)) | .manual, { ... ✅ best one so far
//
//		@Validation(mode: .automatic(delay: .seconds(0.25)) | .manual, { old, new, error in
//			guard let name else { error("Name cannot be nil"); return }
//			if name.isBlank { error("Name cannot be blank") }
//			if name.count < 2 { error("Name cannot be shorter than 2 characters") }
//			if name.rangeOfCharacter(from: .symbols) != nil { error("Name cannot contain special characters or symbols") }
//		})
//		var name: String? = nil

//		$name.validate()

		XCTAssertNil(sut)
		XCTAssertEqual($sut.errors, NonEmptyArray("Input cannot be nil"))

		sut = ""
		XCTAssertNil(sut)
		XCTAssertEqual($sut.errors, NonEmptyArray(
			"Input cannot be blank",
			"Input cannot be shorter than 2 characters"
		))

		sut = "D"
		XCTAssertNil(sut)
		XCTAssertEqual($sut.errors, NonEmptyArray(
			"Input cannot be shorter than 2 characters"
		))

		sut = "Da"
		XCTAssertEqual(sut, "Da")
		XCTAssertNil($sut.errors)

		sut = "David"
		XCTAssertEqual(sut, "David")
		XCTAssertNil($sut.errors)

		sut = "David$"
		XCTAssertNil(sut)
		XCTAssertEqual($sut.errors, NonEmptyArray(
			"Input cannot contain special characters or symbols"
		))
	}
}
