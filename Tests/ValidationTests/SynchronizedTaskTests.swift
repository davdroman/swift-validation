@testable import Validation
import Dependencies
import XCTest

@MainActor
final class SynchronizedTaskTests: XCTestCase {
	@MainActor
	final class Doer {
		private var task: SynchronizedTask? = nil

		func `do`(
			for duration: Duration,
			id: some Hashable & Sendable,
			didFinish: LockIsolated<Bool>,
			cancellationCount: LockIsolated<Int>? = nil
		) {
			task?.cancel()
			task = SynchronizedTask(id: id) { synchronize in
				@Dependency(\.continuousClock) var clock
				try await clock.sleep(for: duration) // simulates work happening
				try await synchronize()
				didFinish.setValue(true)
			} onCancel: {
				cancellationCount?.withValue { $0 += 1 }
			}
		}
	}

	let doer1 = Doer()
	let doer2 = Doer()
	let doer3 = Doer()

	let doer1DidFinish = LockIsolated<Bool>(false)
	let doer2DidFinish = LockIsolated<Bool>(false)
	let doer3DidFinish = LockIsolated<Bool>(false)

	let doer1CancellationCount = LockIsolated<Int>(0)
	let doer2CancellationCount = LockIsolated<Int>(0)
	let doer3CancellationCount = LockIsolated<Int>(0)

	var allDidFinishValues: [Bool] {
		get {
			[
				doer1DidFinish.value,
				doer2DidFinish.value,
				doer3DidFinish.value,
			]
		}
	}

	var allCancellationCountValues: [Int] {
		get {
			[
				doer1CancellationCount.value,
				doer2CancellationCount.value,
				doer3CancellationCount.value,
			]
		}
	}

	let clock = TestClock()

	// MARK: Tests

	override func invokeTest() {
		withMainSerialExecutor {
			super.invokeTest()
		}
	}

	func testHappyPath() async {
		withDependencies {
			$0.continuousClock = clock
		} operation: {
			doer1.do(for: .seconds(1), id: 1, didFinish: doer1DidFinish)
			doer2.do(for: .seconds(2), id: 1, didFinish: doer2DidFinish)
			doer3.do(for: .seconds(3), id: 1, didFinish: doer3DidFinish)
		}

		XCTAssert(allDidFinishValues.allSatisfy { !$0 })

		await clock.advance(by: .seconds(1))

		XCTAssert(allDidFinishValues.allSatisfy { !$0 })

		await clock.advance(by: .seconds(1))

		XCTAssert(allDidFinishValues.allSatisfy { !$0 })

		await clock.advance(by: .seconds(1))

		XCTAssert(allDidFinishValues.allSatisfy { $0 })
	}

	func testAsyncCancellation() async throws {
		withDependencies {
			$0.continuousClock = clock
		} operation: {
			doer1.do(for: .seconds(1), id: 1, didFinish: doer1DidFinish, cancellationCount: doer1CancellationCount)
			doer2.do(for: .seconds(2), id: 1, didFinish: doer2DidFinish, cancellationCount: doer2CancellationCount)
			doer3.do(for: .seconds(3), id: 1, didFinish: doer3DidFinish, cancellationCount: doer3CancellationCount)
		}

		XCTAssert(allDidFinishValues.allSatisfy { !$0 })

		await clock.advance(by: .seconds(1))

		XCTAssert(allDidFinishValues.allSatisfy { !$0 })

		await clock.advance(by: .seconds(1))

		XCTAssert(allDidFinishValues.allSatisfy { !$0 })

		withDependencies {
			$0.continuousClock = clock
		} operation: {
			doer1.do(for: .seconds(1), id: 1, didFinish: doer1DidFinish, cancellationCount: doer1CancellationCount)
		}

		await clock.run()

		XCTAssertEqual(allDidFinishValues, [true, false, false])

		XCTAssertEqual(allCancellationCountValues, [1, 1, 1])
	}

	func testImmediateCancellation() async throws {
		withDependencies {
			$0.continuousClock = clock
		} operation: {
			doer1.do(for: .seconds(1), id: 1, didFinish: doer1DidFinish, cancellationCount: doer1CancellationCount)
			doer2.do(for: .seconds(2), id: 1, didFinish: doer2DidFinish, cancellationCount: doer2CancellationCount)
			doer3.do(for: .seconds(3), id: 1, didFinish: doer3DidFinish, cancellationCount: doer3CancellationCount)
		}

		withDependencies {
			$0.continuousClock = clock
		} operation: {
			doer2.do(for: .seconds(1), id: 1, didFinish: doer2DidFinish, cancellationCount: doer1CancellationCount)
		}

		XCTAssert(allDidFinishValues.allSatisfy { !$0 })

		await clock.run()

		XCTAssertEqual(allDidFinishValues, [false, true, false])

		XCTAssertEqual(allCancellationCountValues, [1, 1, 1])
	}
}
