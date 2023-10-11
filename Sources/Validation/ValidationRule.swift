import Builders

public typealias ValidationRuleHandler<Value, Error> = @Sendable (Value?) -> [Error]

public struct ValidationRule<Value, Error> {
	private let handler: ValidationRuleHandler<Value, Error>

	public init(
		@ArrayBuilder<Error> handler: @escaping ValidationRuleHandler<Value, Error>
	) {
		self.handler = handler
	}

	func validate(_ value: Value?) -> [Error] {
		handler(value)
	}
}

extension ValidationRule: Sendable where Value: Sendable, Error: Sendable {}
