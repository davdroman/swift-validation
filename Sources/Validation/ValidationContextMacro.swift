@attached(memberAttribute)
@attached(extension, conformances: ValidationContext, names: named(validationTraits))
public macro ValidationContext(traits: any ValidationTrait...) = #externalMacro(
	module: "ValidationMacros",
	type: "ValidationContextMacro"
)

@attached(body)
public macro ValidationContextInit(properties: [String]) = #externalMacro(
	module: "ValidationMacros",
	type: "ValidationContextInitMacro"
)
