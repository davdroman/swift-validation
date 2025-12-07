//#if canImport(SwiftUI)
//@testable import CoreValidation
//import NonEmpty
//import SwiftUI
//import XCTest
//
//final class BindingSupportTests: XCTestCase {
//	func testBindingConversion() throws {
//		var validation = Validation { (input: String?) in
//			switch input {
//			case nil: "Cannot be nil"
//			case let input?:
//				if input.isEmpty { "Cannot be empty" }
//				if input.isBlank { "Cannot be blank" }
//			}
//		}
//
//		let validationBinding = Binding(
//			get: { validation },
//			set: { validation = $0 }
//		)
//
//		let sut = Binding(
//			validating: validationBinding,
//			default: ""
//		)
//		XCTAssertEqual(sut.wrappedValue, "")
//		XCTAssertEqual(validation.errors, NonEmptyArray("Cannot be nil"))
//
//		sut.wrappedValue = ""
//		XCTAssertEqual(sut.wrappedValue, "")
//		XCTAssertEqual(validation.errors, NonEmptyArray("Cannot be empty", "Cannot be blank"))
//
//		sut.wrappedValue = " "
//		XCTAssertEqual(sut.wrappedValue, " ")
//		XCTAssertEqual(validation.errors, NonEmptyArray("Cannot be blank"))
//
//		sut.wrappedValue = "  "
//		XCTAssertEqual(sut.wrappedValue, "  ")
//		XCTAssertEqual(validation.errors, NonEmptyArray("Cannot be blank"))
//	}
//}
//#endif
