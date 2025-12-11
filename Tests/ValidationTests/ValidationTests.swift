//import Dependencies
//@testable import Validation
//import XCTest
//
//@MainActor
//final class ValidationTests: XCTestCase {
//	override func invokeTest() {
//		withMainSerialExecutor {
//			super.invokeTest()
//		}
//	}
//
//	func testOptionalError() async {
//		let sut = Validation<String, String?, Void>(
//			wrappedValue: "",
//			context: (),
//			mode: .automatic
//		) { $input, _ in
//			if $input.isUnset { nil }
//			if input.isEmpty { "Cannot be empty" }
//			if input.isBlank { "Cannot be blank" }
//		}
//
//		await Task.yield()
//		XCTAssertEqual(sut.wrappedValue, nil)
//		XCTAssertEqual(sut.errors, NonEmptyArray(nil, "Cannot be empty", "Cannot be blank"))
//
//		sut.wrappedValue = ""
//		await Task.yield()
//		XCTAssertEqual(sut.wrappedValue, nil)
//		XCTAssertEqual(sut.errors, NonEmptyArray(nil, "Cannot be empty", "Cannot be blank"))
//
//		sut.wrappedValue = " "
//		await Task.yield()
//		XCTAssertEqual(sut.wrappedValue, nil)
//		XCTAssertEqual(sut.errors, NonEmptyArray("Cannot be blank"))
//
//		sut.wrappedValue = ""
//		await Task.yield()
//		XCTAssertEqual(sut.wrappedValue, nil)
//		XCTAssertEqual(sut.errors, NonEmptyArray("Cannot be empty", "Cannot be blank"))
//
//		sut.wrappedValue = " "
//		await Task.yield()
//		XCTAssertEqual(sut.wrappedValue, nil)
//		XCTAssertEqual(sut.errors, NonEmptyArray("Cannot be blank"))
//
//		sut.wrappedValue = " S"
//		await Task.yield()
//		XCTAssertEqual(sut.wrappedValue, " S")
//		XCTAssertEqual(sut.errors, nil)
//	}
//
////	func testMutationDuringManualValidation() async {
////		let clock = TestClock()
////		@Validation<String, String?>(mode: .manual, { $input in
////			let _ = try! await clock.sleep(for: .seconds(1))
////			if $input.isUnset { nil }
////			if input.isEmpty { "Cannot be empty" }
////			if input.isBlank { "Cannot be blank" }
////		})
////		var sut: String? = ""
////		await Task.yield()
////		XCTAssertEqual($sut.isIdle, true)
////		XCTAssertEqual(sut, nil)
////		XCTAssertEqual($sut.errors, nil)
////
////		sut = "Input"
////		$sut.validate()
////		sut = ""
////		await clock.advance(by: .seconds(1))
////		XCTAssertEqual($sut.isValid, true)
////		XCTAssertEqual(sut, "Input")
////		XCTAssertEqual($sut.errors, nil)
////	}
////
////	func testAutomaticModeWithDelay() async throws {
////		#if os(Linux)
////		let clock = TestClock()
////		#else
////		let clock = DispatchQueue.test
////		#endif
////		await withDependencies {
////			#if os(Linux)
////			$0.continuousClock = clock
////			#else
////			$0.mainQueue = AnyScheduler(clock)
////			#endif
////		} operation: {
////			@Validation<String, String?>(mode: .automatic(delay: 1), { $input in
////				if $input.isUnset { nil }
////				if input.isEmpty { "Cannot be empty" }
////				if input.isBlank { "Cannot be blank" }
////			})
////			var sut: String? = ""
////			await clock.advance(by: .seconds(1))
////			XCTAssertEqual($sut.isInvalid, true)
////			XCTAssertEqual(sut, nil)
////			XCTAssertEqual($sut.errors, NonEmptyArray(nil, "Cannot be empty", "Cannot be blank"))
////
////			sut = "Input A"
////			await clock.advance(by: .seconds(0.5))
////			XCTAssertEqual($sut.isValidating, true)
////			XCTAssertEqual(sut, nil)
////			XCTAssertEqual($sut.errors, nil)
////
////			sut = "Input B"
////			await clock.advance(by: .seconds(0.5))
////			XCTAssertEqual($sut.isValidating, true)
////			XCTAssertEqual(sut, nil)
////			XCTAssertEqual($sut.errors, nil)
////
////			await clock.advance(by: .seconds(0.5))
////			XCTAssertEqual($sut.isValid, true)
////			XCTAssertEqual(sut, "Input B")
////			XCTAssertEqual($sut.errors, nil)
////		}
////	}
//}
