public import Builders
import Dependencies
public import Observation

@MainActor
@Observable
@propertyWrapper
@dynamicMemberLookup
public final class Validation<Value: Sendable, Error: Sendable, Context: Sendable>: Sendable {
	public typealias Rules = ValidationRules<Value, Error, Context>
	public typealias Phase = ValidationPhase<Value, Error>

	@ObservationIgnored
	private let rules: Rules
	@ObservationIgnored
	private let defaultValue: Value?
	@ObservationIgnored
	private let mode: ValidationMode
	@ObservationIgnored
	private var context: Context?

	private(set) var rawValue: Value?
	public internal(set) var phase: Phase

	public subscript<T>(dynamicMember keyPath: KeyPath<Phase, T>) -> T {
		phase[keyPath: keyPath]
	}

	@ObservationIgnored
	private var task: Task<Void, Never>?

	private init(
		wrappedValue rawValue: Value? = nil,
		of rules: Rules,
		defaultValue: Value?,
		context: Context?,
		mode: ValidationMode = .automatic
	) {
		self.rawValue = rawValue
		self.phase = .idle
		self.rules = rules
		self.defaultValue = defaultValue
		self.context = context
		self.mode = mode

		self.validateIfPossible()
	}

	@_disfavoredOverload
	public convenience init(
		wrappedValue rawValue: Value? = nil,
		of rules: Rules,
		mode: ValidationMode = .automatic
	) where Context == Void {
		self.init(wrappedValue: rawValue, of: rules, defaultValue: nil, context: (), mode: mode)
	}

	@_disfavoredOverload
	public convenience init(
		wrappedValue rawValue: Value? = nil,
		of rules: Rules,
		context: Context? = nil,
		mode: ValidationMode = .automatic
	) {
		self.init(wrappedValue: rawValue, of: rules, defaultValue: nil, context: context, mode: mode)
	}

	@_disfavoredOverload
	public convenience init(
		wrappedValue rawValue: Value? = nil,
		mode: ValidationMode = .automatic,
		@ArrayBuilder<Error> _ handler: @escaping Rules.Handler
	) where Context == Void {
		self.init(wrappedValue: rawValue, of: Rules(handler: handler), context: (), mode: mode)
	}

	@_disfavoredOverload
	public convenience init(
		wrappedValue rawValue: Value? = nil,
		context: Context? = nil,
		mode: ValidationMode = .automatic,
		@ArrayBuilder<Error> _ handler: @escaping Rules.HandlerWithContext
	) {
		self.init(wrappedValue: rawValue, of: Rules(handler: handler), context: context, mode: mode)
	}

	// MARK: support for double optionals

	public convenience init<Wrapped>(
		wrappedValue rawValue: Value? = nil,
		of rules: Rules,
		mode: ValidationMode = .automatic
	) where Value == Wrapped?, Context == Void {
		self.init(wrappedValue: rawValue, of: rules, defaultValue: .some(nil), context: (), mode: mode)
	}

	public convenience init<Wrapped>(
		wrappedValue rawValue: Value? = nil,
		of rules: Rules,
		context: Context? = nil,
		mode: ValidationMode = .automatic
	) where Value == Wrapped? {
		self.init(wrappedValue: rawValue, of: rules, defaultValue: .some(nil), context: context, mode: mode)
	}

	public convenience init<Wrapped>(
		wrappedValue rawValue: Value? = nil,
		mode: ValidationMode = .automatic,
		@ArrayBuilder<Error> _ handler: @escaping Rules.HandlerWithContext
	) where Value == Wrapped?, Context == Void {
		self.init(wrappedValue: rawValue, of: Rules(handler: handler), defaultValue: .some(nil), context: (), mode: mode)
	}

	public convenience init<Wrapped>(
		wrappedValue rawValue: Value? = nil,
		context: Context? = nil,
		mode: ValidationMode = .automatic,
		@ArrayBuilder<Error> _ handler: @escaping Rules.HandlerWithContext
	) where Value == Wrapped? {
		self.init(wrappedValue: rawValue, of: Rules(handler: handler), defaultValue: .some(nil), context: context, mode: mode)
	}

	public var wrappedValue: Value? {
		get {
			phase.value
		}
		set {
			let oldValue = rawValue
			let hasValueChanged = !equals(oldValue as Any, newValue as Any)
			guard hasValueChanged else { return }

			rawValue = newValue

			if let context {
				_validate(in: context)
			} else {
				reportIssue(
					"""
					Validation value mutated without context.

					Validation cannot be performed without a context.

					Please set the context using the `$<property>.setContext(_:)` method before mutating the value — ideally in the initializer of the enclosing type.
					"""
				)
			}
		}
	}

	public var projectedValue: Validation {
		self
	}

	public func setContext(_ context: Context) {
		self.context = context
		validateIfPossible()
	}

	private func validateIfPossible() {
//		if mode.isAutomatic {
		if let context {
			_validate(in: context)
		}
//		}
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

	private func _validate(in context: Context) {
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

			phase = .validating(phase.errors)

			let errors = await rules.evaluate(rawValue, in: context)

			do {
				try Task.checkCancellation()
			} catch {
				return // cancelled
			}

			if !errors.isEmpty {
				phase = .invalid(errors)
			} else if let rawValue = rawValue ?? defaultValue {
				phase = .valid(rawValue)
			} else {
				phase = .invalid([])
			}
		}
	}

	deinit {
		task?.cancel()
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
