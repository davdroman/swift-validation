import Dependencies
public import Observation

@MainActor
@Observable
@propertyWrapper
@dynamicMemberLookup
public final class Validation<Value: Sendable, Error: Sendable>: Sendable {
	@ObservationIgnored
	private let rules: ValidationRules<Value, Error>
	@ObservationIgnored
	private let defaultValue: Value?
	@ObservationIgnored
	private let mode: ValidationMode
	@ObservationIgnored
	private var task: Task<Void, Never>?
	public private(set) var state: _ValidationState<Value, Error>

	private init(
		wrappedValue rawValue: Value? = nil,
		of rules: ValidationRules<Value, Error>,
		defaultValue: Value?,
		mode: ValidationMode = .automatic
	) {
		self.state = .init(rawValue: rawValue, phase: .idle)
		self.rules = rules
		self.defaultValue = defaultValue
		self.mode = mode

		self.validateIfNeeded()
	}

	public convenience init(
		wrappedValue rawValue: Value? = nil,
		of rules: ValidationRules<Value, Error>,
		mode: ValidationMode = .automatic
	) {
		self.init(wrappedValue: rawValue, of: rules, defaultValue: nil, mode: mode)
	}

	public convenience init(
		wrappedValue rawValue: Value? = nil,
		mode: ValidationMode = .automatic,
		@ArrayBuilder<Error> _ handler: @escaping ValidationRulesHandler<Value, Error>
	) {
		self.init(wrappedValue: rawValue, of: ValidationRules(handler: handler), mode: mode)
	}

	// MARK: support for double optionals

	public convenience init<Wrapped>(
		wrappedValue rawValue: Value? = nil,
		of rules: ValidationRules<Value, Error>,
		mode: ValidationMode = .automatic
	) where Value == Wrapped? {
		self.init(wrappedValue: rawValue, of: rules, defaultValue: .some(nil), mode: mode)
	}

	public convenience init<Wrapped>(
		wrappedValue rawValue: Value? = nil,
		mode: ValidationMode = .automatic,
		@ArrayBuilder<Error> _ handler: @escaping ValidationRulesHandler<Value, Error>
	) where Value == Wrapped? {
		self.init(wrappedValue: rawValue, of: ValidationRules(handler: handler), defaultValue: .some(nil), mode: mode)
	}

	public var wrappedValue: Value? {
		get {
			state.value
		}
		set {
			let oldValue = state.rawValue
			let hasValueChanged = !equals(oldValue as Any, newValue as Any)

			if hasValueChanged {
				state.rawValue = newValue
				validateIfNeeded()
			}
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

//	public func validate(id: some Hashable & Sendable) {
//		if mode.isManual {
//			_validate(id: id)
//		}
//	}

//	private func _validate(id: (some Hashable & Sendable)? = AnyHashableSendable?.none) {
//		let operation: SynchronizedTask.Operation = { @MainActor [weak self, history = state.$rawValue] synchronize in
//			guard let self else { return }
//
//			state.phase = .validating
//
//			if let delay = mode.delay {
//				@Dependency(\.continuousClock) var clock
//				try await clock.sleep(for: delay)
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
		task?.cancel()
		task = Task {
			if let delay = mode.delay {
				@Dependency(\.continuousClock) var clock
				do {
					try await clock.sleep(for: delay)
				} catch {
					return // cancelled
				}
			}

			state.phase = .validating(state.phase.errors)

			let errors = await rules.evaluate(state.rawValue)

			do {
				try Task.checkCancellation()
			} catch {
				return // cancelled
			}

			if !errors.isEmpty {
				state.phase = .invalid(errors)
			} else if let rawValue = state.rawValue ?? defaultValue {
				state.phase = .valid(rawValue)
			} else {
				state.phase = .invalid([])
			}
		}
	}

	deinit {
		task?.cancel()
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
