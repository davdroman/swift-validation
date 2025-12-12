public import Builders

public typealias ValidationRulesHandlerWithContext<Value: Sendable, Error: Sendable, Context: Sendable> = @MainActor (Value?, Context) async -> [Error]

public struct ValidationRules<Value: Sendable, Error: Sendable, Context: Sendable>: Sendable {
	private let handler: ValidationRulesHandlerWithContext<Value, Error, Context>

	@_disfavoredOverload
	public init(@ArrayBuilder<Error> handler: @escaping ValidationRulesHandlerWithContext<Value, Error, Context>) {
		self.handler = handler
	}

	public init<Wrapped>(
		@ArrayBuilder<Error> handler: @escaping ValidationRulesHandlerWithContext<Wrapped?, Error, Context>
	) where Value == Wrapped? {
		self.handler = { value, context in
			await handler(value ?? nil, context)
		}
	}

	func evaluate(_ value: Value?, in context: Context) async -> [Error] {
		await handler(value, context)
	}
}

public typealias ValidationRulesHandler<Value: Sendable, Error: Sendable> = @MainActor (Value?) async -> [Error]

extension ValidationRules where Context == Void {
	@_disfavoredOverload
	public init(@ArrayBuilder<Error> handler: @escaping ValidationRulesHandler<Value, Error>) where Context == Void {
		self.handler = { value, _ in await handler(value) }
	}

	public init<Wrapped>(@ArrayBuilder<Error> handler: @escaping ValidationRulesHandler<Wrapped?, Error>) where Value == Wrapped? {
		self.handler = { value, _ in
			await handler(value ?? nil)
		}
	}
}

extension ValidationRules {
	public static var noop: ValidationRules {
		ValidationRules { _, _ in }
	}
}
