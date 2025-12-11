public import Builders

public struct ValidationRules<Value: Sendable, Error: Sendable, Context: Sendable>: Sendable {
	public typealias Handler = @MainActor (Value?, Context) async -> [Error]

	private let handler: Handler

	public init(@ArrayBuilder<Error> handler: @escaping Handler) {
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
