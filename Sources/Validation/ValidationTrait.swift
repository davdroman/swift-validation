import Dependencies

public protocol ValidationTrait: Sendable {
	func beforeValidation() async throws(CancellationError)
	func mutatePhase(isInitial: Bool, mutate: () -> Void)
	func afterValidation() async throws(CancellationError)
}

public extension ValidationTrait {
	@_transparent func beforeValidation() async throws(CancellationError) {}
	@_transparent func mutatePhase(isInitial: Bool, mutate: () -> Void) { mutate() }
	@_transparent func afterValidation() async throws(CancellationError) {}
}

extension [any ValidationTrait] {
	@inlinable
	func beforeValidation() async throws(CancellationError) {
		for trait in self {
			try await trait.beforeValidation()
		}
	}

	func mutatePhase(isInitial: Bool, mutate: () -> Void) {
		withoutActuallyEscaping(mutate) { mutate in
			let operation = reversed().reduce(mutate) { next, trait in
				{ trait.mutatePhase(isInitial: isInitial, mutate: next) }
			}
			operation()
		}
	}

	@inlinable
	func afterValidation() async throws(CancellationError) {
		for trait in self {
			try await trait.afterValidation()
		}
	}
}
