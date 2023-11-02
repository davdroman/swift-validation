import Builders
import NonEmpty

@MainActor
@propertyWrapper
@dynamicMemberLookup
open class ValidationBase<Value, Error> {
	@_spi(package) open var state: ValidationState<Value, Error>
	package let rule: ValidationRule<Value, Error>

	public init(
		wrappedValue rawValue: Value,
		rule: ValidationRule<Value, Error>
	) {
		self.state = .init(rawValue: rawValue, phase: .idle)
		self.rule = rule

		self.validateIfNeeded()
	}

	public convenience init(
		wrappedValue rawValue: Value,
		@ArrayBuilder<Error> _ handler: @escaping ValidationRuleHandler<Value, Error>
	) {
		self.init(
			wrappedValue: rawValue,
			rule: .init(handler: handler)
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
		// TODO: guard mode.isAutomatic else { return }
		validate()
	}

	public func validate() {
		// TODO: spin up and store an unstructured Task {

		state.phase = .validating

		if let errors = NonEmpty(rawValue: rule.validate(state.rawValue)) {
			state.phase = .invalid(errors)
		} else {
			state.phase = .valid(state.rawValue)
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
