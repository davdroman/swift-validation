import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ValidationMacroPlugin: CompilerPlugin {
	let providingMacros: [any Macro.Type] = [
		ValidationMacro.self,
	]
}
