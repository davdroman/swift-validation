@testable import CoreValidation
import Dependencies
import XCTest

@MainActor
final class SynchronizedTaskTests: XCTestCase {
	func testHappyPath() async {
		@MainActor
		final class Doer {
			func `do`(for duration: Duration, id: some Hashable, didFinish: ActorIsolated<Bool>) {
				SynchronizedTask(id: id) { synchronize in
					@Dependency(\.continuousClock) var clock
					do {
						try await clock.sleep(for: duration) // simulates work happening
						try await synchronize()
						await didFinish.setValue(true)
					} catch {
						XCTFail(error.localizedDescription)
					}
				}
			}
		}

		let doer1 = Doer()
		let doer2 = Doer()
		let doer3 = Doer()
		let doer4 = Doer()
		let doer5 = Doer()

		let doer1DidFinish = ActorIsolated<Bool>(false)
		let doer2DidFinish = ActorIsolated<Bool>(false)
		let doer3DidFinish = ActorIsolated<Bool>(false)
		let doer4DidFinish = ActorIsolated<Bool>(false)
		let doer5DidFinish = ActorIsolated<Bool>(false)

		func getDidFinishValues() async -> [Bool] {
			await [
				doer1DidFinish.value,
				doer2DidFinish.value,
				doer3DidFinish.value,
				doer4DidFinish.value,
				doer5DidFinish.value,
			]
		}

		let clock = TestClock()

		withDependencies {
			$0.continuousClock = clock
		} operation: {
			doer1.do(for: .seconds(2), id: 1, didFinish: doer1DidFinish)
			doer2.do(for: .seconds(1), id: 1, didFinish: doer2DidFinish)
			doer3.do(for: .seconds(2), id: 1, didFinish: doer3DidFinish)
			doer4.do(for: .seconds(3), id: 1, didFinish: doer4DidFinish)
			doer5.do(for: .seconds(1), id: 1, didFinish: doer5DidFinish)
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
}
