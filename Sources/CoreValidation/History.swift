@propertyWrapper
public struct History<Value> {
	public var oldValues: [Value] = []

	public var wrappedValue: Value {
		didSet {
			oldValues.append(oldValue)
		}
	}

	public var projectedValue: Self {
		self
	}

	public init(initialValue: Value) {
		self.wrappedValue = initialValue
	}

	public init(wrappedValue: Value) {
		self.init(initialValue: wrappedValue)
	}

	public init(projectedValue: Self) {
		self = projectedValue
	}
}

extension History: Equatable where Value: Equatable {}
extension History: Hashable where Value: Hashable {}
