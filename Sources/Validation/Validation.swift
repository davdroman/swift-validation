import Dependencies
import NonEmpty
public import Observation

@MainActor
@Observable
@propertyWrapper
@dynamicMemberLookup
public final class Validation<Value: Sendable, Error: Sendable> {
	@ObservationIgnored
	private let rules: ValidationRules<Value, Error>
	@ObservationIgnored
	private let mode: ValidationMode
//	@ObservationIgnored
//	private var task: (any Cancellable)?
	public private(set) var state: _ValidationState<Value, Error>

	public init(
		wrappedValue rawValue: Value,
		of rules: ValidationRules<Value, Error>,
		mode: ValidationMode = .automatic
	) {
		self.state = .init(rawValue: rawValue, phase: .idle)
		self.rules = rules
		self.mode = mode

		self.validateIfNeeded()
	}

	public convenience init(
		wrappedValue rawValue: Value,
		mode: ValidationMode = .automatic,
		@ArrayBuilder<Error> _ handler: @escaping ValidationRulesHandler<Value, Error>
	) {
		self.init(
			wrappedValue: rawValue,
			of: ValidationRules(handler: handler),
			mode: mode
		)
	}

	public var wrappedValue: Value? {
		get {
			state.value
		}
		set {
			guard let newValue else { return }

			let oldValue = state.rawValue
			let hasValueChanged = !equals(oldValue, newValue)

			state.rawValue = newValue

//			if hasValueChanged {
//				clearErrors()
//			}

			validateIfNeeded()
		}
	}

	public var projectedValue: Validation<Value, Error> {
		self
	}

	private func validateIfNeeded() {
		if mode.isAutomatic {
			_validate()
		}
	}

	public func validate() {
		if mode.isManual {
			_validate()
		}
	}

//	public func validate(id: some Hashable) {
//		if mode.isManual {
//			_validate(id: id)
//		}
//	}

//	private func _validate(id: (some Hashable)? = Optional<AnyHashable>.none) {
//		let operation: SynchronizedTask.Operation = { [weak self, history = state.$rawValue] synchronize in
//			guard let self else { return }
//
//			state.phase = .validating
//
//			if let delay = mode.delay {
//				#if os(Linux)
//				@Dependency(\.continuousClock) var clock
//				#else
//				@Dependency(\.mainQueue) var clock
//				#endif
//				try await clock.sleep(for: .seconds(delay))
//			}
//
//			let errors = await rules.evaluate(history)
//
//			// TODO: unit test this
//			// Group validation should be stopped if any one `synchronize()` is cancelled while
//			// other validations are ongoing.
//			try await synchronize()
//
//			if let errors = NonEmpty(rawValue: errors) {
//				state.phase = .invalid(errors)
//			} else {
//				state.phase = .valid(history.currentValue)
//			}
//		}
//
//		task?.cancel()
//		task = if let id {
//			SynchronizedTask(id: id, operation: operation, onCancel: { /*self.state.phase = .idle*/ })
//		} else {
//			Task { try? await operation({ try Task.checkCancellation() }) }
//		}
//	}

	private func _validate() {
		Task<Void, Never> {
//			guard let self else { return }
			state.phase = .validating

			if let delay = mode.delay {
				@Dependency(\.continuousClock) var clock
				do {
					try await clock.sleep(for: .seconds(delay))
				} catch {
					return // cancelled
				}
			}

			let errors = await rules.evaluate(state.$rawValue)

			if let errors = NonEmpty(rawValue: errors) {
				state.phase = .invalid(errors)
			} else {
				state.phase = .valid(state.rawValue)
			}
		}
	}

	public func clearErrors() {
		if state.isInvalid {
			state.phase = .idle
		}
	}

	public subscript<T>(dynamicMember keyPath: KeyPath<_ValidationState<Value, Error>, T>) -> T {
		state[keyPath: keyPath]
	}
}

// https://forums.swift.org/t/why-cant-existential-types-be-compared/59118/3
fileprivate func equals(_ lhs: Any, _ rhs: Any) -> Bool {
	func open<A: Equatable>(_ lhs: A, _ rhs: Any) -> Bool {
		lhs == (rhs as? A)
	}

	guard let lhs = lhs as? any Equatable
	else { return false }

	return open(lhs, rhs)
}
