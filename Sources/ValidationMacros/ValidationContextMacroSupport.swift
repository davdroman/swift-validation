import SwiftDiagnostics
import SwiftSyntax

struct ValidationContextTypeInfo {
	let name: TokenSyntax
	let members: MemberBlockItemListSyntax
	let inheritanceClause: InheritanceClauseSyntax?

	init?(declaration: some DeclGroupSyntax) {
		if let classDecl = declaration.as(ClassDeclSyntax.self) {
			name = classDecl.name
			members = classDecl.memberBlock.members
			inheritanceClause = classDecl.inheritanceClause
			return
		}

		if let actorDecl = declaration.as(ActorDeclSyntax.self) {
			name = actorDecl.name
			members = actorDecl.memberBlock.members
			inheritanceClause = actorDecl.inheritanceClause
			return
		}

		return nil
	}
}

enum ValidationContextMacroDiagnostics {
	struct UnsupportedType: DiagnosticMessage {
		var message: String {
			"'@ValidationContext' can only be applied to a class or actor."
		}

		var diagnosticID: MessageID {
			.init(domain: "ValidationContextMacro", id: "UnsupportedType")
		}

		var severity: DiagnosticSeverity { .error }
	}
}

func validationProperties(in members: MemberBlockItemListSyntax) -> [String] {
	var names: [String] = []

	for member in members {
		guard let variable = member.decl.as(VariableDeclSyntax.self) else { continue }
		guard !variable.isStaticOrClass else { continue }
		guard variable.attributes.containsValidationAttribute else { continue }

		for binding in variable.bindings {
			guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
			names.append(pattern.identifier.text)
		}
	}

	return names
}

func validationContextTraitsExpressions(from attribute: AttributeSyntax) -> [ExprSyntax] {
	guard let arguments = attribute.arguments else { return [] }
	guard case let .argumentList(argumentList) = arguments else { return [] }

	var expressions: [ExprSyntax] = []
	var collecting = false

	for argument in argumentList {
		if argument.label?.text == "traits" {
			collecting = true
			expressions.append(argument.expression)
			continue
		}

		if collecting, argument.label == nil {
			expressions.append(argument.expression)
		}
	}

	if expressions.isEmpty {
		let unlabeled = argumentList.filter { $0.label == nil }
		if !unlabeled.isEmpty {
			expressions = unlabeled.map { $0.expression }
		}
	}

	return expressions
}

func hasValidationContextConformance(in inheritanceClause: InheritanceClauseSyntax?) -> Bool {
	guard let inheritanceClause else { return false }
	return inheritanceClause.inheritedTypes.contains { inheritedType in
		let name = inheritedType.type.trimmedDescription
		return name == "ValidationContext" || name.hasSuffix(".ValidationContext")
	}
}

func qualifiedTypeName(for declaration: some DeclGroupSyntax, named baseName: String) -> String {
	let ancestorNames = ancestorTypeNames(startingAt: Syntax(declaration).parent)
	guard !ancestorNames.isEmpty else {
		return baseName
	}

	return (ancestorNames.reversed() + [baseName]).joined(separator: ".")
}

func enclosingTypeInfo(for declaration: some DeclSyntaxProtocol) -> ValidationContextTypeInfo? {
	var current = Syntax(declaration).parent

	while let node = current {
		if let classDecl = node.as(ClassDeclSyntax.self) {
			return ValidationContextTypeInfo(declaration: classDecl)
		}

		if let actorDecl = node.as(ActorDeclSyntax.self) {
			return ValidationContextTypeInfo(declaration: actorDecl)
		}

		current = node.parent
	}

	return nil
}

func ancestorTypeNames(startingAt node: Syntax?) -> [String] {
	var names: [String] = []
	var current = node

	while let node = current {
		if let parentStruct = node.as(StructDeclSyntax.self) {
			names.append(parentStruct.name.text)
		} else if let parentClass = node.as(ClassDeclSyntax.self) {
			names.append(parentClass.name.text)
		} else if let parentEnum = node.as(EnumDeclSyntax.self) {
			names.append(parentEnum.name.text)
		} else if let parentActor = node.as(ActorDeclSyntax.self) {
			names.append(parentActor.name.text)
		} else if let parentExtension = node.as(ExtensionDeclSyntax.self) {
			names.append(parentExtension.extendedType.trimmedDescription)
		}

		current = node.parent
	}

	return names
}

extension AttributeListSyntax {
	var containsValidationAttribute: Bool {
		contains { attribute in
			guard let attribute = attribute.as(AttributeSyntax.self) else { return false }
			return attribute.isValidationAttribute
		}
	}

	func containsAttribute(named name: String) -> Bool {
		contains { attribute in
			guard let attribute = attribute.as(AttributeSyntax.self) else { return false }
			let attributeName = attribute.attributeName.trimmedDescription
			return attributeName == name || attributeName.hasSuffix(".\(name)")
		}
	}
}

extension AttributeSyntax {
	var isValidationAttribute: Bool {
		let name = attributeName.trimmedDescription
		return name == "Validation" || name.hasSuffix(".Validation")
	}
}

extension VariableDeclSyntax {
	var isStaticOrClass: Bool {
		modifiers.contains { modifier in
			switch modifier.name.tokenKind {
			case .keyword(.static), .keyword(.class):
				return true
			default:
				return false
			}
		}
	}
}
