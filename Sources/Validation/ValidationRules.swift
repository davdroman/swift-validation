public typealias ValidationRulesHandler<Value, Error> = @Sendable (ValidationInput<Value>) async -> [Error]

public struct ValidationRules<Value, Error> {
	private let handler: ValidationRulesHandler<Value, Error>

	public init(
		@ArrayBuilder<Error> handler: @escaping ValidationRulesHandler<Value, Error>
	) {
		self.handler = handler
	}

	func evaluate(_ value: ValidationInput<Value>) async -> [Error] {
		await handler(value)
	}
}
