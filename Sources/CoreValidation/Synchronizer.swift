import ConcurrencyExtras

@MainActor
final class Synchronizer {
	static let shared = Synchronizer()

	private var tasks: LockIsolated<[AnyHashable: Int]> = .init([:])

	func start(id: some Hashable) {
		self.tasks.withValue { $0[id, default: 0] += 1 }
	}

	func finish(id: some Hashable) async {
		guard tasks.value[id] != nil else { return }
		tasks.withValue { $0[id, default: 0] -= 1 }
		while tasks.value[id, default: 0] > 0 {
			await Task.yield()
		}
	}
}
