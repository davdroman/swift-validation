import NonEmpty

public enum ValidationPhase<Value, Error> {
	case idle
	case validating
	case invalid(NonEmptyArray<Error>)
	case valid(Value)
}

extension ValidationPhase: Equatable where Value: Equatable, Error: Equatable {}
extension ValidationPhase: Hashable where Value: Hashable, Error: Hashable {}

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
	public var errors: NonEmptyArray<Error>? {
		if case let .invalid(errors) = self {
			return errors
		}
		return nil
	}

	public var value: Value? {
		if case let .valid(value) = self {
			return value
		}
		return nil
	}
}
