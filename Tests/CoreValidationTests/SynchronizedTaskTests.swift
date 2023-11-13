@testable import CoreValidation
import Dependencies
import XCTest

@available(iOS 16, macOS 13, tvOS 13, watchOS 6, *)
@MainActor
final class SynchronizedTaskTests: XCTestCase {
	@MainActor
	final class Doer {
		private var task: SynchronizedTask? = nil

		func `do`(
			for duration: Duration,
			id: some Hashable,
			didFinish: ActorIsolated<Bool>,
			cancellationCount: ActorIsolated<Int>? = nil
		) {
			task?.cancel()
			task = SynchronizedTask(id: id) { synchronize in
				@Dependency(\.continuousClock) var clock
				try await clock.sleep(for: duration) // simulates work happening
				try await synchronize()
				await didFinish.setValue(true)
			} onCancel: {
				await cancellationCount?.withValue { $0 += 1 }
			}
		}
	}

	let doer1 = Doer()
	let doer2 = Doer()
	let doer3 = Doer()

	let doer1DidFinish = ActorIsolated<Bool>(false)
	let doer2DidFinish = ActorIsolated<Bool>(false)
	let doer3DidFinish = ActorIsolated<Bool>(false)

	let doer1CancellationCount = ActorIsolated<Int>(0)
	let doer2CancellationCount = ActorIsolated<Int>(0)
	let doer3CancellationCount = ActorIsolated<Int>(0)

	var allDidFinishValues: [Bool] {
		get async {
			await [
				doer1DidFinish.value,
				doer2DidFinish.value,
				doer3DidFinish.value,
			]
		}
	}

	var allCancellationCountValues: [Int] {
		get async {
			await [
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

		var didFinishValues = await allDidFinishValues
		XCTAssert(didFinishValues.allSatisfy { !$0 })

		await clock.advance(by: .seconds(1))

		didFinishValues = await allDidFinishValues
		XCTAssert(didFinishValues.allSatisfy { !$0 })

		await clock.advance(by: .seconds(1))

		didFinishValues = await allDidFinishValues
		XCTAssert(didFinishValues.allSatisfy { !$0 })

		await clock.advance(by: .seconds(1))

		didFinishValues = await allDidFinishValues
		XCTAssert(didFinishValues.allSatisfy { $0 })
	}

	func testAsyncCancellation() async throws {
		withDependencies {
			$0.continuousClock = clock
		} operation: {
			doer1.do(for: .seconds(1), id: 1, didFinish: doer1DidFinish, cancellationCount: doer1CancellationCount)
			doer2.do(for: .seconds(2), id: 1, didFinish: doer2DidFinish, cancellationCount: doer2CancellationCount)
			doer3.do(for: .seconds(3), id: 1, didFinish: doer3DidFinish, cancellationCount: doer3CancellationCount)
		}

		var didFinishValues = await allDidFinishValues
		XCTAssert(didFinishValues.allSatisfy { !$0 })

		await clock.advance(by: .seconds(1))

		didFinishValues = await allDidFinishValues
		XCTAssert(didFinishValues.allSatisfy { !$0 })

		await clock.advance(by: .seconds(1))

		didFinishValues = await allDidFinishValues
		XCTAssert(didFinishValues.allSatisfy { !$0 })

		withDependencies {
			$0.continuousClock = clock
		} operation: {
			doer1.do(for: .seconds(1), id: 1, didFinish: doer1DidFinish, cancellationCount: doer1CancellationCount)
		}

		await clock.run()

		didFinishValues = await allDidFinishValues
		XCTAssertEqual(didFinishValues, [true, false, false])

		let cancellationCountValues = await allCancellationCountValues
		XCTAssertEqual(cancellationCountValues, [1, 1, 1])
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

		var didFinishValues = await allDidFinishValues
		XCTAssert(didFinishValues.allSatisfy { !$0 })

		await clock.run()

		didFinishValues = await allDidFinishValues
		XCTAssertEqual(didFinishValues, [false, true, false])

		let cancellationCountValues = await allCancellationCountValues
		XCTAssertEqual(cancellationCountValues, [1, 1, 1])
	}
}
