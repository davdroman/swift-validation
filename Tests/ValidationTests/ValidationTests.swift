//@testable import Validation
//import XCTest
//
//final class ValidationTests: XCTestCase {
//	func testPropertyWrapper() throws {
//		guard #available(iOS 17, macOS 14, tvOS 17, watchOS 9, *) else {
//			throw XCTSkip()
//		}
//
//		@Validation({ input in
//			switch input {
//			case nil: "Input cannot be nil"
//			case let input?:
//				if input.isBlank { "Input cannot be blank" }
//				if input.count < 2 { "Input cannot be shorter than 2 characters" }
//				if input.rangeOfCharacter(from: .symbols) != nil { "Input cannot contain special characters or symbols" }
//			}
//		})
//		var input: String? = nil
//
//		XCTAssertNil(input)
//		XCTAssertEqual($input.errors, NonEmptyArray("Input cannot be nil"))
//
//		input = ""
//		XCTAssertNil(input)
//		XCTAssertEqual($input.errors, NonEmptyArray(
//			"Input cannot be blank",
//			"Input cannot be shorter than 2 characters"
//		))
//
//		input = "D"
//		XCTAssertNil(input)
//		XCTAssertEqual($input.errors, NonEmptyArray(
//			"Input cannot be shorter than 2 characters"
//		))
//
//		input = "Da"
//		XCTAssertEqual(input, "Da")
//		XCTAssertNil($input.errors)
//
//		input = "David"
//		XCTAssertEqual(input, "David")
//		XCTAssertNil($input.errors)
//
//		input = "David$"
//		XCTAssertNil(input)
//		XCTAssertEqual($input.errors, NonEmptyArray(
//			"Input cannot contain special characters or symbols"
//		))
//	}
//}
