import Builders
@testable import Validation
import XCTest

final class ValidationTests: XCTestCase {
	func testPropertyWrapper() throws {
		guard #available(iOS 17, macOS 14, tvOS 17, watchOS 9, *) else {
			throw XCTSkip()
		}

		struct InputState {
			@Validation({ name in
				switch name {
				case nil: "Name cannot be nil"
				case let name?:
					if name.isBlank { "Name cannot be blank" }
					if name.count < 2 { "Name cannot be shorter than 2 characters" }
					if name.rangeOfCharacter(from: .symbols) != nil { "Name cannot contain special characters or symbols" }
				}
			})
			var name: String? = nil

//			@Validation(mode: .live(delay: .seconds(0.25)) | .late, { ... ❌ - too ambiguous ("live" being vernacular in TCA, "late" is too much of an obscure UX term)
//			@Validation(mode: .asYouType(delay: .seconds(0.25)) | .onSubmit, { ... ❌ - should be agnostic (e.g. sliders)
//			@Validation(mode: .automatic(delay: .seconds(0.25)) | .manual, { ... ✅ best one so far

//			@Validation(mode: .automatic(delay: .seconds(0.25)) | .manual, { old, new, error in
//				guard let name else { error("Name cannot be nil"); return }
//				if name.isBlank { error("Name cannot be blank") }
//				if name.count < 2 { error("Name cannot be shorter than 2 characters") }
//				if name.rangeOfCharacter(from: .symbols) != nil { error("Name cannot contain special characters or symbols") }
//			})
//			var name: String? = nil

//			$name.validate()
		}

		let sut = InputState(name: nil)
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
