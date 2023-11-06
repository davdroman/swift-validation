import ConcurrencyExtras

typealias SynchronizedTaskOperation = (_ synchronize: () async throws -> Void) async -> Void

@MainActor
@discardableResult
func SynchronizedTask(
	id: some Hashable,
	priority: TaskPriority? = nil,
	operation: @escaping SynchronizedTaskOperation
) -> Task<Void, Never> {
	SynchronizedTaskPool.shared.start(id: id)

	return Task {
		await operation({ try await SynchronizedTaskPool.shared.finish(id: id) })
	}
}

@MainActor
fileprivate final class SynchronizedTaskPool {
	static let shared = SynchronizedTaskPool()

	private var tasks: LockIsolated<[AnyHashable: Int]> = .init([:])

	func start(id: some Hashable) {
		self.tasks.withValue { $0[id, default: 0] += 1 }
	}

	func finish(id: some Hashable) async throws {
		guard tasks.value[id] != nil else { return }
		tasks.withValue { $0[id, default: 0] -= 1 }
		while tasks.value[id, default: 0] > 0 {
			await Task.yield()
		}
	}

	private func cancel(id: some Hashable) {

	}
}
