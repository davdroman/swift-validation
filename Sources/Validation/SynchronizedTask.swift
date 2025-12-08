import ConcurrencyExtras
import Foundation

protocol Cancellable {
	func cancel()
}

extension Task: Cancellable {}
extension SynchronizedTask: Cancellable {}

struct SynchronizedTask {
	typealias Operation = @Sendable (_ synchronize: @Sendable () async throws -> Void) async throws -> Void

	private let path: SynchronizedTaskPool.Path
	private let task: Task<Void, Never>

	@discardableResult
	init(
		id: some Hashable & Sendable,
		priority: TaskPriority? = nil,
		operation: @escaping Operation,
		onCancel: (@Sendable () async -> Void)? = nil // TODO: is this needed for handling cancellation of manual group validation?
	) {
		self.path = SynchronizedTaskPool.shared.prepare(id: id)
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

fileprivate final class SynchronizedTaskPool: Sendable {
	static let shared = SynchronizedTaskPool()

	struct Path: Hashable, Sendable {
		let id: AnyHashableSendable
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

	let seeds: LockIsolated<[AnyHashableSendable: UUID]> = .init([:])
	let tasks: LockIsolated<[Path: TasksState]> = .init([:])

	func prepare(id: some Hashable & Sendable) -> Path {
		let identifier = AnyHashableSendable(id)
		let path = seeds.withValue { seeds in
			let seed = seeds[identifier] ?? UUID()
			if seeds[identifier] == nil {
				seeds[identifier] = seed
			}
			return Path(id: identifier, seed: seed)
		}

		tasks.withValue {
			var state = $0[path] ?? .init()
			state.prepare()
			$0[path] = state
		}

		return path
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
