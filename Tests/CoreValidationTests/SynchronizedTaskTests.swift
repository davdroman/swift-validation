@testable import CoreValidation
import Dependencies
import XCTest

@MainActor
final class SynchronizedTaskTests: XCTestCase {
	override func invokeTest() {
		withMainSerialExecutor {
			super.invokeTest()
		}
	}

	func testHappyPath() async {
		@MainActor
		final class Doer {
			func `do`(for duration: Duration, id: some Hashable, didFinish: ActorIsolated<Bool>) {
				SynchronizedTask(id: id) { synchronize in
					@Dependency(\.continuousClock) var clock
					try await clock.sleep(for: duration) // simulates work happening
					try await synchronize()
					await didFinish.setValue(true)
				}
			}
		}

		let doer1 = Doer()
		let doer2 = Doer()
		let doer3 = Doer()

		let doer1DidFinish = ActorIsolated<Bool>(false)
		let doer2DidFinish = ActorIsolated<Bool>(false)
		let doer3DidFinish = ActorIsolated<Bool>(false)

		func getDidFinishValues() async -> [Bool] {
			await [
				doer1DidFinish.value,
				doer2DidFinish.value,
				doer3DidFinish.value,
			]
		}

		let clock = TestClock()

		withDependencies {
			$0.continuousClock = clock
		} operation: {
			doer1.do(for: .seconds(1), id: 1, didFinish: doer1DidFinish)
			doer2.do(for: .seconds(2), id: 1, didFinish: doer2DidFinish)
			doer3.do(for: .seconds(3), id: 1, didFinish: doer3DidFinish)
		}

		var didFinishValues = await getDidFinishValues()
		XCTAssert(didFinishValues.allSatisfy { !$0 })

		await clock.advance(by: .seconds(1))

		didFinishValues = await getDidFinishValues()
		XCTAssert(didFinishValues.allSatisfy { !$0 })

		await clock.advance(by: .seconds(1))

		didFinishValues = await getDidFinishValues()
		XCTAssert(didFinishValues.allSatisfy { !$0 })

		await clock.advance(by: .seconds(1))

		didFinishValues = await getDidFinishValues()
		XCTAssert(didFinishValues.allSatisfy { $0 })
	}

	func testCancellation() async throws {
		@MainActor
		final class Doer {
			private var task: Task<Void, Never>? = nil

			func `do`(for duration: Duration, id: some Hashable, didFinish: ActorIsolated<Bool>) {
				task?.cancel()
				task = SynchronizedTask(id: id) { synchronize in
					@Dependency(\.continuousClock) var clock
					try await clock.sleep(for: duration) // simulates work happening
					try await synchronize()
					await didFinish.setValue(true)
				}
			}
		}

		let doer1 = Doer()
		let doer2 = Doer()
		let doer3 = Doer()

		let doer1DidFinish = ActorIsolated<Bool>(false)
		let doer2DidFinish = ActorIsolated<Bool>(false)
		let doer3DidFinish = ActorIsolated<Bool>(false)

		func getDidFinishValues() async -> [Bool] {
			await [
				doer1DidFinish.value,
				doer2DidFinish.value,
				doer3DidFinish.value,
			]
		}

		let clock = TestClock()

		withDependencies {
			$0.continuousClock = clock
		} operation: {
			doer1.do(for: .seconds(1), id: 1, didFinish: doer1DidFinish)
			doer2.do(for: .seconds(2), id: 1, didFinish: doer2DidFinish)
			doer3.do(for: .seconds(3), id: 1, didFinish: doer3DidFinish)
		}

		var didFinishValues = await getDidFinishValues()
		XCTAssert(didFinishValues.allSatisfy { !$0 })

		await clock.advance(by: .seconds(1))

		didFinishValues = await getDidFinishValues()
		XCTAssert(didFinishValues.allSatisfy { !$0 })

		await clock.advance(by: .seconds(1))

		didFinishValues = await getDidFinishValues()
		XCTAssert(didFinishValues.allSatisfy { !$0 })

		withDependencies {
			$0.continuousClock = clock
		} operation: {
			doer1.do(for: .seconds(1), id: 1, didFinish: doer1DidFinish)
			doer2.do(for: .seconds(2), id: 1, didFinish: doer2DidFinish)
			doer3.do(for: .seconds(3), id: 1, didFinish: doer3DidFinish)
		}

		await clock.advance(by: .seconds(1))

		didFinishValues = await getDidFinishValues()
		XCTAssert(didFinishValues.allSatisfy { !$0 })

		await clock.advance(by: .seconds(1))

		didFinishValues = await getDidFinishValues()
		XCTAssert(didFinishValues.allSatisfy { !$0 })

		await clock.advance(by: .seconds(1))

		didFinishValues = await getDidFinishValues()
		XCTAssert(didFinishValues.allSatisfy { $0 })

		try await clock.checkSuspension()
	}
}
