import Builders

public typealias ValidationRuleHandler<Value, Error> = @Sendable (History<Value>) -> [Error]

public struct ValidationRule<Value, Error> {
	private let handler: ValidationRuleHandler<Value, Error>

	public init(
		@ArrayBuilder<Error> handler: @escaping ValidationRuleHandler<Value, Error>
	) {
		self.handler = handler
	}

	func validate(_ value: History<Value>) -> [Error] {
		handler(value)
	}
}
