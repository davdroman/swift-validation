import CasePaths
import NonEmpty

@CasePathable
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
		self.is(\.idle)
	}

	public var isValidating: Bool {
		self.is(\.validating)
	}

	public var isInvalid: Bool {
		self.is(\.invalid)
	}

	public var isValid: Bool {
		self.is(\.valid)
	}
}

extension ValidationPhase {
	public var errors: NonEmptyArray<Error>? {
		self[case: \.invalid]
	}

	public var value: Value? {
		self[case: \.valid]
	}
}
