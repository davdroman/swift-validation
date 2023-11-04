import Builders

public typealias ValidationRuleHandler<Value, Error> = @Sendable (History<Value>) -> [Error]

public struct ValidationRule<Value, Error> {
	let mode: ValidationMode
	private let handler: ValidationRuleHandler<Value, Error>

	public init(
		mode: ValidationMode,
		@ArrayBuilder<Error> handler: @escaping ValidationRuleHandler<Value, Error>
	) {
		self.mode = mode
		self.handler = handler
	}

	func evaluate(_ value: History<Value>) -> [Error] {
		handler(value)
	}
}
