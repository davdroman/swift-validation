import Builders
import Validated

//@propertyWrapper
@dynamicMemberLookup
open class ValidationBase<Value, Error> {
	@_spi(package) open var state: ValidationState<Value, Error>
	package let rule: ValidationRule<Value, Error>

	public init(
		wrappedValue rawValue: Value? = nil,
		rule: ValidationRule<Value, Error>
	) {
		self.state = .init(rawValue: rawValue, phase: .idle)
		self.rule = rule
	}

	public convenience init(
		wrappedValue rawValue: Value? = nil,
		@ArrayBuilder<Error> _ handler: @escaping ValidationRuleHandler<Value, Error>
	) {
		self.init(
			wrappedValue: rawValue,
			rule: .init(handler: handler)
		)
	}

	open var wrappedValue: Value? {
		get { state.value }
		set {
			state.rawValue = newValue
			// TODO: perform validation synchronously
			// TODO: make async by spinning up and storing an unstructured Task {
		}
	}

//	public var validated: Validated<Value, Error>? {
//		if let errors = NonEmpty(rawValue: rule.validate(state.rawValue)) {
//			return .invalid(errors)
//		} else if let value = rawValue {
//			return .valid(value)
//		} else {
//			return nil
//		}
//	}

//	public subscript<T>(dynamicMember keyPath: KeyPath<Validated<Value, Error>, T?>) -> T? {
//		validated?[keyPath: keyPath]
//	}

	public subscript<T>(dynamicMember keyPath: KeyPath<ValidationState<Value, Error>, T>) -> T {
		state[keyPath: keyPath]
	}
}
