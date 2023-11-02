import Combine
import CoreValidation

public typealias CombineValidation<Value, Error> = Validation<Value, Error>

@propertyWrapper
@dynamicMemberLookup
public final class Validation<Value, Error>: ValidationBase<Value, Error>, ObservableObject {
	private(set) public override var rawValue: Value? {
		willSet {
			objectWillChange.send()
		}
	}
//	public var state: Value?
	private let rule: ValidationRule<Value, Error>

	public init(
		wrappedValue rawValue: Value? = nil,
		rule: ValidationRule<Value, Error>
	) {
		self.rawValue = rawValue
		self.rule = rule
	}

	public convenience init(
		wrappedValue rawValue: Value? = nil,
		@ArrayBuilder<Error> _ handler: @escaping ValidationRuleHandler<Value, Error>
	) {
		self.init(
			wrappedValue: rawValue,
			rule: .init(handler: handler)
		)
	}

//	public var projectedValue: Validation<Value, Error> {
//		get { self }
//		@available(*, unavailable)
//		set { fatalError() }
//	}

	public var wrappedValue: Value? {
		get {
			validated?.value
		}
		set {
			rawValue = newValue
		}
	}
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


