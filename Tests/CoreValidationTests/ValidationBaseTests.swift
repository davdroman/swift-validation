import ConcurrencyExtras
@testable import CoreValidation
import NonEmpty
import XCTest

@MainActor
final class ValidationBaseTests: XCTestCase {
	override func invokeTest() {
		withMainSerialExecutor {
			super.invokeTest()
		}
	}

	func testOptionalError() async {
		@ValidationBase<String, String?>({ $input in
			if $input.isUnset { nil }
			if input.isEmpty { "Cannot be empty" }
			if input.isBlank { "Cannot be blank" }
		})
		var sut: String? = ""
		await Task.yield()
		XCTAssertEqual(sut, nil)
		XCTAssertEqual($sut.errors, NonEmptyArray(nil, "Cannot be empty", "Cannot be blank"))

		sut = ""
		await Task.yield()
		XCTAssertEqual(sut, nil)
		XCTAssertEqual($sut.errors, NonEmptyArray(nil, "Cannot be empty", "Cannot be blank"))

		sut = " "
		await Task.yield()
		XCTAssertEqual(sut, nil)
		XCTAssertEqual($sut.errors, NonEmptyArray("Cannot be blank"))

		sut = ""
		await Task.yield()
		XCTAssertEqual(sut, nil)
		XCTAssertEqual($sut.errors, NonEmptyArray("Cannot be empty", "Cannot be blank"))

		sut = " "
		await Task.yield()
		XCTAssertEqual(sut, nil)
		XCTAssertEqual($sut.errors, NonEmptyArray("Cannot be blank"))

		sut = " S"
		await Task.yield()
		XCTAssertEqual(sut, " S")
		XCTAssertEqual($sut.errors, nil)
	}
}
