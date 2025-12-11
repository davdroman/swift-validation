import Builders

//@attached(accessor, names: named(get), named(set))
@attached(peer, names: arbitrary)
public macro Validation<Value, Error, Context>(
	context: Context? = nil,
	mode: ValidationMode = .automatic,
	@ArrayBuilder<Error> _ handler: @escaping ValidationRules<Value, Error, Context>.Handler
) = #externalMacro(module: "ValidationMacro", type: "ValidationMacro")
