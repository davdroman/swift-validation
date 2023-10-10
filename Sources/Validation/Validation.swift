import Builders
@_exported import Validated

@propertyWrapper
@dynamicMemberLookup
public struct Validation<Value, Error> {
	@_spi(Validation) public var rawValue: Value?
	private let validate: ValidationRules<Value, Error>

	public init(
		wrappedValue rawValue: Value? = nil,
		rules handler: ValidationRules<Value, Error>
	) {
		self.rawValue = rawValue
		self.validate = handler
	}

	public init(
		wrappedValue rawValue: Value? = nil,
		@ArrayBuilder<Error> rules handler: @escaping ValidationRulesHandler<Value, Error>
	) {
		self.init(
			wrappedValue: rawValue,
			rules: .init(handler: handler)
		)
	}

	public var projectedValue: Self {
		self
	}

	public var validated: Validated<Value, Error>? {
		if let errors = NonEmpty(rawValue: validate(rawValue)) {
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

extension Validation: Sendable where Value: Sendable, Error: Sendable {}

extension Validation: Equatable where Value: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.rawValue == rhs.rawValue
	}
}

extension Validation: Hashable where Value: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(rawValue)
	}
}
