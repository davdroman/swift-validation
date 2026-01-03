import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct ValidationContextMacro: MemberAttributeMacro, ExtensionMacro {
	static func expansion(
		of _: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingAttributesFor member: some DeclSyntaxProtocol,
		in _: some MacroExpansionContext
	) throws -> [AttributeSyntax] {
		guard let typeInfo = ValidationContextTypeInfo(declaration: declaration) else {
			return []
		}

		guard let initializer = member.as(InitializerDeclSyntax.self) else { return [] }
		let properties = typeInfo.membersValidationProperties
		guard !properties.isEmpty else { return [] }

		let attributes = initializer.attributes
		if attributes.containsAttribute(named: "ValidationContextInit") {
			return []
		}

		return [validationContextInitAttribute(with: properties)]
	}

	static func expansion(
		of node: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingExtensionsOf _: some TypeSyntaxProtocol,
		conformingTo _: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [ExtensionDeclSyntax] {
		guard let typeInfo = ValidationContextTypeInfo(declaration: declaration) else {
			context.diagnose(
				Diagnostic(node: Syntax(node), message: ValidationContextMacroDiagnostics.UnsupportedType())
			)
			return []
		}

		guard !hasValidationContextConformance(in: typeInfo.inheritanceClause) else { return [] }

		let typeName = qualifiedTypeName(for: declaration, named: typeInfo.name.text)
		let extensionDecl: DeclSyntax
		let traitsExpressions = validationContextTraitsExpressions(from: node)
		if traitsExpressions.isEmpty {
			extensionDecl =
				"""
				extension \(raw: typeName): ValidationContext {}
				"""
		} else {
			let traitsSource = traitsExpressions.map { $0.trimmedDescription }.joined(separator: ", ")
			extensionDecl =
				"""
				extension \(raw: typeName): ValidationContext {
					nonisolated var validationTraits: [any ValidationTrait] {
						[\(raw: traitsSource)]
					}
				}
				"""
		}

		return [extensionDecl.cast(ExtensionDeclSyntax.self)]
	}
}

private extension ValidationContextTypeInfo {
	var membersValidationProperties: [String] {
		validationProperties(in: members)
	}
}

private func validationContextInitAttribute(with properties: [String]) -> AttributeSyntax {
	let arguments = properties.map { "\"\($0)\"" }.joined(separator: ", ")
	return AttributeSyntax(
		stringLiteral: "@ValidationContextInit(properties: [\(arguments)])"
	)
}
