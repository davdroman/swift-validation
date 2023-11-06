import Builders
import Dependencies
import NonEmpty

@MainActor
@propertyWrapper
@dynamicMemberLookup
open class ValidationBase<Value, Error> {
	@_spi(package) open var state: ValidationState<Value, Error>
	private let rules: ValidationRules<Value, Error>
	private let mode: ValidationMode
	private var task: Task<Void, Never>? = nil

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

	open var wrappedValue: Value? {
		get {
			state.value
		}
		set {
			guard let newValue else { return } // NO-OP when assigning nil. Hopefully one day we'll get asymmetric get/set.

			let oldValue = state.rawValue
			let hasValueChanged = !equals(oldValue, newValue)

			state.rawValue = newValue

			if hasValueChanged {
				clearErrors()
			}

			validateIfNeeded()
		}
	}

	public var projectedValue: ValidationBase<Value, Error> {
		get { self }
		@available(*, unavailable)
		set { fatalError() }
	}

	private func validateIfNeeded() {
		if mode.is(\.automatic) {
			_validate()
		}
	}

	public func validate(id: (some Hashable)? = Optional<AnyHashable>.none) {
		if mode.is(\.manual) {
			_validate()
		}
	}

	private func _validate(id: (some Hashable)? = Optional<AnyHashable>.none) {
		state.phase = .validating

		let operation: SynchronizedTaskOperation = { [weak self, history = state.$rawValue] synchronize in
			guard let self else { return }

			if let delay = mode.delay {
				#if os(Linux)
				@Dependency(\.continuousClock) var clock
				#else
				@Dependency(\.mainQueue) var clock
				#endif
				try await clock.sleep(for: .seconds(delay))
			}

			let errors = await rules.evaluate(history)

			// TODO: unit test this
			// Group validation should be stopped if synchronizer is cancelled while
			// validation is ongoing.
			try await synchronize()

			if let errors = NonEmpty(rawValue: errors) {
				state.phase = .invalid(errors)
			} else {
				state.phase = .valid(history.currentValue)
			}
		}

		task?.cancel()
		// TODO: write a unit test to verify this
		// I think this might need to be deferred to the next run loop in order
		// for synchronizer to be able to catch up to the latest cancellation
		task = if let id {
			SynchronizedTask(id: id, operation: operation)
		} else {
			Task { try? await operation({}) }
		}
	}

	// TODO: `reset`?
	public func clearErrors() {
		if state.isInvalid {
			state.phase = .idle
		}
	}

//	public subscript<T>(dynamicMember keyPath: KeyPath<Validated<Value, Error>, T?>) -> T? {
//		validated?[keyPath: keyPath]
//	}

	public subscript<T>(dynamicMember keyPath: KeyPath<ValidationState<Value, Error>, T>) -> T {
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
