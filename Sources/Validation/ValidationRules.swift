import Builders

public typealias ValidationRulesHandler<Value, Error> = @Sendable (Value?) -> [Error]

public struct ValidationRules<Value, Error> {
	private let handler: ValidationRulesHandler<Value, Error>

	public init(
		@ArrayBuilder<Error> handler: @escaping ValidationRulesHandler<Value, Error>
	) {
		self.handler = handler
	}

	func callAsFunction(_ value: Value?) -> [Error] {
		handler(value)
	}
}

extension ValidationRules: Sendable where Value: Sendable, Error: Sendable {}
