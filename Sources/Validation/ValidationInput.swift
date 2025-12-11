//@propertyWrapper
//public struct ValidationInput<Value> {
//	public var oldValues: [Value] = []
//
//	public var currentValue: Value {
//		wrappedValue
//	}
//
//	public var wrappedValue: Value {
//		didSet {
//			oldValues.append(oldValue)
//		}
//	}
//
//	public var projectedValue: Self {
//		self
//	}
//
//	public init(initialValue: Value) {
//		self.wrappedValue = initialValue
//	}
//
//	public init(wrappedValue: Value) {
//		self.init(initialValue: wrappedValue)
//	}
//
//	public init(projectedValue: Self) {
//		self = projectedValue
//	}
//}
//
//extension ValidationInput: Equatable where Value: Equatable {}
//extension ValidationInput: Hashable where Value: Hashable {}
//extension ValidationInput: Sendable where Value: Sendable {}
//
//extension ValidationInput where Value: StringProtocol {
//	public var isUnset: Bool {
//		wrappedValue.isEmpty && oldValues.filter { !$0.isEmpty }.isEmpty
//	}
//}
