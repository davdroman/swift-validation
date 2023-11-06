import ConcurrencyExtras

typealias SynchronizedTaskOperation = (_ synchronize: () async throws -> Void) async throws -> Void

@MainActor
@discardableResult
func SynchronizedTask(
	id: some Hashable,
	priority: TaskPriority? = nil,
	operation: @escaping SynchronizedTaskOperation
) -> Task<Void, Never> {
	SynchronizedTaskPool.shared.prepare(id: id)

	return Task {
		SynchronizedTaskPool.shared.start(id: id)
		try? await operation({ try await SynchronizedTaskPool.shared.finish(id: id) })
	}
}

@MainActor
fileprivate final class SynchronizedTaskPool {
	static let shared = SynchronizedTaskPool()

	struct TasksState {
		var count: Int
		var inProgress: Bool
	}

	var tasks: LockIsolated<[AnyHashable: TasksState]> = .init([:])

	func prepare(id: some Hashable) {
		tasks.withValue {
			var state = $0[id] ?? .init(count: 0, inProgress: false)
			if state.inProgress {
				$0[id] = .init(count: 1, inProgress: false)
			} else {
				state.count += 1
				$0[id] = state
			}
		}
	}

	func start(id: some Hashable) {
		tasks.withValue {
			$0[id]?.inProgress = true
		}
	}

	func finish(id: some Hashable) async throws {
		tasks.withValue {
			if var state = $0[id] {
				state.count -= 1
				state.inProgress = true
				$0[id] = state
			}
		}

		while let ongoingTaskCount = tasks.value[id]?.count, ongoingTaskCount > 0 {
			await Task.yield()
		}

		if tasks.value[id] == nil {
			throw CancellationError()
		}
	}
}
