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
		else { return false }
	}

	public var isValidating: Bool {
		if case .validating = self { return true }
		else { return false }
	}

	public var isInvalid: Bool {
		if case .invalid = self { return true }
		else { return false }
	}

	public var isValid: Bool {
		if case .valid = self { return true }
		else { return false }
	}
}

extension ValidationPhase {
	public var errors: NonEmptyArray<Error>? {
		if case .invalid(let errors) = self { return errors }
		else { return nil }
	}

	public var value: Value? {
		if case .valid(let value) = self { return value }
		else { return nil }
	}
}
