import ConcurrencyExtras
import Foundation

@MainActor
struct AnyTask {
	private let _cancel: () -> Void

	init(_ task: SynchronizedTask) {
		self._cancel = task.cancel
	}

	init(_ task: Task<Void, Never>) {
		self._cancel = task.cancel
	}

	func cancel() {
		_cancel()
	}
}

@MainActor
struct SynchronizedTask {
	typealias Operation = (_ synchronize: () async throws -> Void) async throws -> Void

	private let path: SynchronizedTaskPool.Path
	private let task: Task<Void, Never>
	private var onCancel: (() async -> Void)?

	@discardableResult
	init(
		id: some Hashable,
		priority: TaskPriority? = nil,
		operation: @escaping Operation,
		onCancel: (() async -> Void)? = nil
	) {
		self.path = SynchronizedTaskPool.shared.prepare(id: id)
		self.onCancel = onCancel
		self.task = Task { [path] in
			do {
				try SynchronizedTaskPool.shared.start(path: path)
				try await operation({ try await SynchronizedTaskPool.shared.finish(path: path) })
			} catch is CancellationError {
				await onCancel?()
			} catch {}
		}
	}

	func cancel() {
		SynchronizedTaskPool.shared.cancel(path: path)
		task.cancel()
	}
}

@MainActor
fileprivate final class SynchronizedTaskPool {
	static let shared = SynchronizedTaskPool()

	struct Path: Hashable {
		let id: AnyHashable
		let seed: UUID
	}

	struct TasksState {
		enum Status {
			case idle
			case inProgress
			case cancelled
		}

		var count: Int = 0
		var status: Status = .idle

		mutating func prepare() {
			switch status {
			case .idle:
				count += 1
			case .inProgress, .cancelled:
				count = 1
				status = .idle
			}
		}

		mutating func start() throws {
			switch status {
			case .idle:
				status = .inProgress
			case .inProgress:
				break
			case .cancelled:
				throw CancellationError()
			}
		}

		mutating func finish() throws {
			switch status {
			case .idle:
				assertionFailure("Internal state inconsistency: cannot synchronize idle tasks")
			case .inProgress:
				count -= 1
			case .cancelled:
				throw CancellationError()
			}
		}

		mutating func cancel() {
			switch status {
			case .idle, .inProgress:
				status = .cancelled
			case .cancelled:
				break
			}
		}
	}

	var seeds: LockIsolated<[AnyHashable: UUID]> = .init([:])
	var tasks: LockIsolated<[Path: TasksState]> = .init([:])

	func prepare(id: some Hashable) -> Path {
		seeds.withValue { seeds in
			tasks.withValue {
				let seed = seeds[id] ?? UUID()
				if seeds[id] == nil {
					seeds[id] = seed
				}
				let path = Path(id: id, seed: seed)

				var state = $0[path] ?? .init()
				state.prepare()
				$0[path] = state

				return path
			}
		}
	}

	func start(path: Path) throws {
		seeds.withValue {
			$0[path.id] = nil
		}
		try tasks.withValue {
			try $0[path]?.start()
		}
	}

	func finish(path: Path) async throws {
		try tasks.withValue {
			try $0[path]?.finish()
		}

		while let state = tasks.value[path], state.status == .inProgress, state.count > 0 {
			await Task.yield()
		}

		if tasks.value[path]?.status != .inProgress {
			throw CancellationError()
		}
	}

	func cancel(path: Path) {
		seeds.withValue {
			$0[path.id] = nil
		}
		tasks.withValue {
			$0[path]?.cancel()
		}
	}
}
