public enum ValidationPhase<Value, Error> {
	case idle
	case validating([Error]?)
	case invalid([Error])
	case valid(Value)
}

extension ValidationPhase: Equatable where Value: Equatable, Error: Equatable {}
extension ValidationPhase: Hashable where Value: Hashable, Error: Hashable {}
extension ValidationPhase: Sendable where Value: Sendable, Error: Sendable {}

extension ValidationPhase {
	public var isIdle: Bool {
		if case .idle = self { true } else { false }
	}

	public var isValidating: Bool {
		if case .validating = self { true } else { false }
	}

	public var isInvalid: Bool {
		if case .invalid = self { true } else { false }
	}

	public var isValid: Bool {
		if case .valid = self { true } else { false }
	}
}

extension ValidationPhase {
	public var errors: [Error]? {
		switch self {
		case let .validating(errors?), let .invalid(errors):
			errors
		default:
			nil
		}
	}

	public var value: Value? {
		switch self {
		case let .valid(value):
			value
		default:
			nil
		}
	}
}
