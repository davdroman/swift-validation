@_spi(package) import CoreValidation
#if canImport(Observation)
import Observation
#endif

@available(iOS 17, macOS 14, tvOS 17, watchOS 9, *)
public typealias SwiftValidation<Value, Error> = Validation<Value, Error>

@available(iOS 17, macOS 14, tvOS 17, watchOS 9, *)
@propertyWrapper
#if canImport(Observation)
@Observable
#endif
public final class Validation<Value, Error>: ValidationBase<Value, Error> {
	@_spi(package) public override var state: ValidationState<Value, Error> {
		get { super.state }
		set { super.state = newValue }
	}

	public override var wrappedValue: Value? {
		get { super.wrappedValue }
		set { super.wrappedValue = newValue }
	}

	public var projectedValue: Validation<Value, Error> {
		get { self }
		@available(*, unavailable) 
		set { fatalError() }
	}

//	public var wrappedValue: Value? {
//		get {
//			validated?.value
//		}
//		set {
//			rawValue = newValue
//		}
//	}
}

//extension Validation: Sendable where Value: Sendable, Error: Sendable {}

//extension Validation: Equatable where Value: Equatable {
//	public static func == (lhs: Self, rhs: Self) -> Bool {
//		lhs.rawValue == rhs.rawValue
//	}
//}

//extension Validation: Hashable where Value: Hashable {
//	public func hash(into hasher: inout Hasher) {
//		hasher.combine(rawValue)
//	}
//}
