@testable import CoreValidation
import XCTest

@MainActor
final class SynchronizerTests: XCTestCase {
	func test() async throws {
		@MainActor
		final class Printer {
			let name: String
			let synchronizer: Synchronizer

			init(name: String, synchronizer: Synchronizer) {
				self.name = name
				self.synchronizer = synchronizer
			}

			func waitRandomlyAndPrint(id: some Hashable) {
				synchronizer.start(id: id)

				Task {
					let seconds = UInt64.random(in: 1...3)
					try? await Task.sleep(nanoseconds: NSEC_PER_SEC * seconds)
					await synchronizer.finish(id: id)
					print("\(name) printed in \(seconds) seconds!")
				}
			}
		}

		let sut = Synchronizer()

		let printer1 = Printer(name: "Printer 1", synchronizer: sut)
		let printer2 = Printer(name: "Printer 2", synchronizer: sut)
		let printer3 = Printer(name: "Printer 3", synchronizer: sut)
		let printer4 = Printer(name: "Printer 4", synchronizer: sut)
		let printer5 = Printer(name: "Printer 5", synchronizer: sut)

		printer1.waitRandomlyAndPrint(id: 1)
		printer2.waitRandomlyAndPrint(id: 1)
		printer3.waitRandomlyAndPrint(id: 1)
		printer4.waitRandomlyAndPrint(id: 1)
		printer5.waitRandomlyAndPrint(id: 1)

		await sut.wait(id: 1)
	}
}
