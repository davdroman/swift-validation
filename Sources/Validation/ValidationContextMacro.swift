@attached(memberAttribute)
@attached(extension, conformances: ValidationContext)
public macro ValidationContext() = #externalMacro(
	module: "ValidationMacros",
	type: "ValidationContextMacro"
)

@attached(body)
public macro ValidationContextInit(properties: [String]) = #externalMacro(
	module: "ValidationMacros",
	type: "ValidationContextInitMacro"
)
