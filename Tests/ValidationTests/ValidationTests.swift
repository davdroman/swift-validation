@testable import Validation
import XCTest

@MainActor
final class ValidationTests: XCTestCase {
//	override func invokeTest() {
//		withMainSerialExecutor {
//			super.invokeTest()
//		}
//	}

//	func testOptionalError() async {
//		@Validation(rules: { input -> [String?] in
//			switch input {
//			case nil:
//				nil
//			case let input?:
//				if input.isEmpty { "Cannot be empty" }
//				if input.allSatisfy(\.isWhitespace) { "Cannot be blank" }
//			}
//		})
//		var sut: String? = ""
//		await Task.yield()
//		XCTAssertEqual(sut, nil)
//		XCTAssertEqual($sut.errors, [nil, "Cannot be empty", "Cannot be blank"])
//
//		sut = ""
//		await Task.yield()
//		XCTAssertEqual(sut, nil)
//		XCTAssertEqual($sut.errors, [nil, "Cannot be empty", "Cannot be blank"])
//
//		sut = " "
//		await Task.yield()
//		XCTAssertEqual(sut, nil)
//		XCTAssertEqual($sut.errors, ["Cannot be blank"])
//
//		sut = ""
//		await Task.yield()
//		XCTAssertEqual(sut, nil)
//		XCTAssertEqual($sut.errors, ["Cannot be empty", "Cannot be blank"])
//
//		sut = " "
//		await Task.yield()
//		XCTAssertEqual(sut, nil)
//		XCTAssertEqual($sut.errors, ["Cannot be blank"])
//
//		sut = " S"
//		await Task.yield()
//		XCTAssertEqual(sut, " S")
//		XCTAssertEqual($sut.errors, nil)
//	}

//	func testDebounceTrait() async throws {
//		#if os(Linux)
//		let clock = TestClock()
//		#else
//		let clock = DispatchQueue.test
//		#endif
//		await withDependencies {
//			#if os(Linux)
//			$0.continuousClock = clock
//			#else
//			$0.mainQueue = AnyScheduler(clock)
//			#endif
//		} operation: {
//			@Validation<String, String?>(mode: .automatic(delay: 1), { $input in
//				if $input.isUnset { nil }
//				if input.isEmpty { "Cannot be empty" }
//				if input.isBlank { "Cannot be blank" }
//			})
//			var sut: String? = ""
//			await clock.advance(by: .seconds(1))
//			XCTAssertEqual($sut.isInvalid, true)
//			XCTAssertEqual(sut, nil)
//			XCTAssertEqual($sut.errors, NonEmptyArray(nil, "Cannot be empty", "Cannot be blank"))
//
//			sut = "Input A"
//			await clock.advance(by: .seconds(0.5))
//			XCTAssertEqual($sut.isValidating, true)
//			XCTAssertEqual(sut, nil)
//			XCTAssertEqual($sut.errors, nil)
//
//			sut = "Input B"
//			await clock.advance(by: .seconds(0.5))
//			XCTAssertEqual($sut.isValidating, true)
//			XCTAssertEqual(sut, nil)
//			XCTAssertEqual($sut.errors, nil)
//
//			await clock.advance(by: .seconds(0.5))
//			XCTAssertEqual($sut.isValid, true)
//			XCTAssertEqual(sut, "Input B")
//			XCTAssertEqual($sut.errors, nil)
//		}
//	}
}
