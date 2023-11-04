import Builders

public typealias ValidationRulesHandler<Value, Error> = @Sendable (History<Value>) -> [Error]

public struct ValidationRules<Value, Error> {
	private let handler: ValidationRulesHandler<Value, Error>

	public init(
		@ArrayBuilder<Error> handler: @escaping ValidationRulesHandler<Value, Error>
	) {
		self.handler = handler
	}

	func evaluate(_ value: History<Value>) -> [Error] {
		handler(value)
	}
}
