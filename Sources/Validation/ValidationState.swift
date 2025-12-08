@dynamicMemberLookup
public struct _ValidationState<Value, Error> {
	@ValidationInput
	public internal(set) var rawValue: Value
	public internal(set) var phase: ValidationPhase<Value, Error>

	public subscript<T>(dynamicMember keyPath: KeyPath<ValidationPhase<Value, Error>, T>) -> T {
		phase[keyPath: keyPath]
	}
}

extension _ValidationState: Equatable where Value: Equatable, Error: Equatable {}
extension _ValidationState: Hashable where Value: Hashable, Error: Hashable {}
extension _ValidationState: Sendable where Value: Sendable, Error: Sendable {}
