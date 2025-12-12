public import Builders

// TODO: initializer that flattens double optionals
public struct ValidationRules<Value: Sendable, Error: Sendable, Context: Sendable>: Sendable {
	public typealias Handler = @MainActor (Value?) async -> [Error]
	public typealias HandlerWithContext = @MainActor (Value?, Context) async -> [Error]

	private let handler: HandlerWithContext

	@_disfavoredOverload
	public init(@ArrayBuilder<Error> handler: @escaping Handler) where Context == Void {
		self.handler = { value, _ in await handler(value) }
	}

	@_disfavoredOverload
	public init(@ArrayBuilder<Error> handler: @escaping HandlerWithContext) {
		self.handler = handler
	}

	func evaluate(_ value: Value?, in context: Context) async -> [Error] {
		await handler(value, context)
	}
}

extension ValidationRules {
	public static var noop: ValidationRules {
		ValidationRules { _, _ in }
	}
}
