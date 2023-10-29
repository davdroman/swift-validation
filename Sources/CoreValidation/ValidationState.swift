@dynamicMemberLookup
public struct ValidationState<Value, Error> {
	public internal(set) var rawValue: Value?
	public internal(set) var phase: ValidationPhase<Value, Error>

	public subscript<T>(dynamicMember keyPath: KeyPath<ValidationPhase<Value, Error>, T>) -> T {
		phase[keyPath: keyPath]
	}
}
