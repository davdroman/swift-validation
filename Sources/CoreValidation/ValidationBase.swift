import Builders
import Dependencies
import NonEmpty

@MainActor
@propertyWrapper
@dynamicMemberLookup
open class ValidationBase<Value, Error> {
	@_spi(package) open var state: ValidationState<Value, Error>
	package let rules: ValidationRules<Value, Error>
	package let mode: ValidationMode

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
			state.rawValue = newValue
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
			validate()
		}
	}

	public func validate(id: (some Hashable)? = Optional<AnyHashable>.none) {
		state.phase = .validating

		// We gotta make a copy this early on in case the value is changed
		// later while validation is in progress.
		// TODO: unit test this scenario
		let history = state.$rawValue

		if let id {
			Synchronizer.shared.start(id: id)
		}

		// TODO: store the Task to debounce it when a new one comes in
		Task {
			if let delay = mode.delay {
				#if os(Linux)
				@Dependency(\.continuousClock) var clock
				try? await clock.sleep(for: .seconds(delay))
				#else
				@Dependency(\.mainQueue) var mainQueue
				try? await mainQueue.sleep(for: .seconds(delay))
				#endif
			}

			let errors = rules.evaluate(history) // TODO: make async

			await Synchronizer.shared.finish(id: id)

			if let errors = NonEmpty(rawValue: errors) {
				state.phase = .invalid(errors)
			} else {
				state.phase = .valid(history.currentValue)
			}
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
