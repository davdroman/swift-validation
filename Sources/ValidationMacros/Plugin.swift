import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ValidationMacrosPlugin: CompilerPlugin {
	let providingMacros: [any Macro.Type] = [
		ValidationContextMacro.self,
		ValidationContextInitMacro.self,
	]
}
