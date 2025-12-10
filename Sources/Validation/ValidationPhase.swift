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
		if case .idle = self { return true }
		return false
	}

	public var isValidating: Bool {
		if case .validating = self { return true }
		return false
	}

	public var isInvalid: Bool {
		if case .invalid = self { return true }
		return false
	}

	public var isValid: Bool {
		if case .valid = self { return true }
		return false
	}
}

extension ValidationPhase {
	public var errors: [Error]? {
		switch self {
		case let .validating(errors?), let .invalid(errors):
			return errors
		default:
			return nil
		}
	}

	public var value: Value? {
		if case let .valid(value) = self {
			return value
		}
		return nil
	}
}
