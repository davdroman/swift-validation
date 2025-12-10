public typealias ValidationRulesHandler<Value, Error> = @Sendable (Value?) async -> [Error]

public struct ValidationRules<Value: Sendable, Error: Sendable>: Sendable {
	private let handler: ValidationRulesHandler<Value, Error>

	public init(
		@ArrayBuilder<Error> handler: @escaping ValidationRulesHandler<Value, Error>
	) {
		self.handler = handler
	}

	func evaluate(_ value: Value?) async -> [Error] {
		await handler(value)
	}
}
