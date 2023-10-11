import Builders
#if canImport(Observation)
import Observation
#endif
@_exported import Validated

public enum ValidationState<Value, Error> {
	case validating
	case invalid
	case valid
}

@propertyWrapper
@dynamicMemberLookup
#if canImport(Observation)
@Observable
#endif
@available(iOS 17, macOS 14, tvOS 17, watchOS 9, *)
public final class Validation<Value, Error> {
	private(set) public var rawValue: Value?
//	public var state: Value?
	private let rule: ValidationRule<Value, Error>

	public init(
		wrappedValue rawValue: Value? = nil,
		rule: ValidationRule<Value, Error>
	) {
		self.rawValue = rawValue
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

	public var projectedValue: Validation<Value, Error> {
		self
	}

//	internal var readOnlyProjectedValue: Validation<Value, Error> {
//		get { self }
//		set { fatalError() }
//	}

	public var validated: Validated<Value, Error>? {
		if let errors = NonEmpty(rawValue: rule.validate(rawValue)) {
			return .invalid(errors)
		} else if let value = rawValue {
			return .valid(value)
		} else {
			return nil
		}
	}

	public subscript<T>(dynamicMember keyPath: KeyPath<Validated<Value, Error>, T?>) -> T? {
		validated?[keyPath: keyPath]
	}

	public var wrappedValue: Value? {
		get {
			validated?.value
		}
		set {
			rawValue = newValue
		}
	}
}

//extension Validation: Sendable where Value: Sendable, Error: Sendable {}

//extension Validation: Equatable where Value: Equatable {
//	public static func == (lhs: Self, rhs: Self) -> Bool {
//		lhs.rawValue == rhs.rawValue
//	}
//}

//extension Validation: Hashable where Value: Hashable {
//	public func hash(into hasher: inout Hasher) {
//		hasher.combine(rawValue)
//	}
//}
