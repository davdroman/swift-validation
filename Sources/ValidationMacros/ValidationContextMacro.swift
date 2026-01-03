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

		let properties = validationProperties(in: typeInfo.members)
		if !properties.isEmpty, !hasInitializer(in: typeInfo.members) {
			if let fixIt = missingInitializerFixIt(for: declaration) {
				context.diagnose(
					Diagnostic(
						node: Syntax(node),
						message: ValidationContextMacroDiagnostics.MissingInitializer(),
						fixIt: fixIt
					)
				)
			} else {
				context.diagnose(
					Diagnostic(
						node: Syntax(node),
						message: ValidationContextMacroDiagnostics.MissingInitializer()
					)
				)
			}
		}

		guard !hasValidationContextConformance(in: typeInfo.inheritanceClause) else { return [] }

		let typeName = qualifiedTypeName(for: declaration, named: typeInfo.name.text)
		let extensionDecl: DeclSyntax =
			"""
			extension \(raw: typeName): ValidationContext {}
			"""

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

private func missingInitializerFixIt(for declaration: some DeclGroupSyntax) -> FixIt? {
	if let classDecl = declaration.as(ClassDeclSyntax.self) {
		let initializerItem = MemberBlockItemSyntax(
			leadingTrivia: Trivia(pieces: [.newlines(1), .tabs(1)]),
			decl: emptyInitializerDecl()
		)
		var members = [initializerItem]
		members.append(contentsOf: classDecl.memberBlock.members)
		let updatedMembers = MemberBlockItemListSyntax(members)
		let updatedMemberBlock = classDecl.memberBlock.with(\.members, updatedMembers)
		let updatedDecl = classDecl.with(\.memberBlock, updatedMemberBlock)
		return FixIt(
			message: MacroExpansionFixItMessage("Insert 'init() {}'"),
			changes: [
				.replace(oldNode: Syntax(classDecl), newNode: Syntax(updatedDecl)),
			]
		)
	}

	if let actorDecl = declaration.as(ActorDeclSyntax.self) {
		let initializerItem = MemberBlockItemSyntax(
			leadingTrivia: Trivia(pieces: [.newlines(1), .tabs(1)]),
			decl: emptyInitializerDecl()
		)
		var members = [initializerItem]
		members.append(contentsOf: actorDecl.memberBlock.members)
		let updatedMembers = MemberBlockItemListSyntax(members)
		let updatedMemberBlock = actorDecl.memberBlock.with(\.members, updatedMembers)
		let updatedDecl = actorDecl.with(\.memberBlock, updatedMemberBlock)
		return FixIt(
			message: MacroExpansionFixItMessage("Insert 'init() {}'"),
			changes: [
				.replace(oldNode: Syntax(actorDecl), newNode: Syntax(updatedDecl)),
			]
		)
	}

	return nil
}

private func emptyInitializerDecl() -> DeclSyntax {
	DeclSyntax(stringLiteral: "init() {}")
}
