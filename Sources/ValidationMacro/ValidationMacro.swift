import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct ValidationMacro: AccessorMacro, PeerMacro {
	static func expansion(
		of node: AttributeSyntax,
		providingAccessorsOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [AccessorDeclSyntax] {
		let property = try ValidationProperty(from: declaration)
		let storageName = property.storageName

		let getter = AccessorDeclSyntax(accessorSpecifier: .keyword(.get)) {
			CodeBlockItemListSyntax {
				"return \(raw: storageName).wrappedValue"
			}
		}

		let setter = AccessorDeclSyntax(accessorSpecifier: .keyword(.set)) {
			CodeBlockItemListSyntax {
				"\(raw: storageName).wrappedValue = newValue"
			}
		}

		return [getter, setter]
	}

	static func expansion(
		of node: AttributeSyntax,
		providingPeersOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		let property = try ValidationProperty(from: declaration)
		let arguments = try ValidationArguments(attribute: node)
		let typeArguments = property.typeArguments(from: node)

		let storageModifiers = property.accessModifier.isEmpty ? "" : "\(property.accessModifier) "
		let call = ValidationCall(
			typeArguments: typeArguments,
			property: property,
			arguments: arguments
		)

		let storage: DeclSyntax =
			"""
			\(raw: storageModifiers)lazy var \(raw: property.storageName) = \(raw: call.description)
			"""

		return [storage]
	}
}

private struct ValidationCall: CustomStringConvertible {
	let typeArguments: String
	let property: ValidationProperty
	let arguments: ValidationArguments

	var description: String {
		var pieces: [String] = []

		if let initializer = property.wrappedValueArgument {
			pieces.append("wrappedValue: \(initializer)")
		}

		pieces.append("context: \(arguments.contextDescription)")

		if let mode = arguments.mode {
			pieces.append("mode: \(mode.trimmedDescription)")
		}

		let callArguments = pieces.joined(separator: ", ")
		let closure = arguments.handler.trimmedDescription

		let call = callArguments.isEmpty
			? "Validation<\(typeArguments)>()"
			: "Validation<\(typeArguments)>(\(callArguments))"

		return "\(call) \(closure)"
	}
}

private struct ValidationArguments {
	let context: ExprSyntax?
	let mode: ExprSyntax?
	let handler: ExprSyntax

	init(attribute: AttributeSyntax) throws {
		var contextExpression: ExprSyntax?
		var modeExpression: ExprSyntax?
		var handlerExpression: ExprSyntax?

		if case let .argumentList(arguments)? = attribute.arguments {
			for argument in arguments {
				if let label = argument.label?.text {
					switch label {
					case "context":
						if contextExpression != nil {
							throw ValidationDiagnostic.duplicateArgument("context", node: Syntax(argument)).error
						}
						contextExpression = argument.expression
					case "mode":
						if modeExpression != nil {
							throw ValidationDiagnostic.duplicateArgument("mode", node: Syntax(argument)).error
						}
						modeExpression = argument.expression
					default:
						throw ValidationDiagnostic.unsupportedArgument(label, node: Syntax(argument)).error
					}
				} else if handlerExpression == nil {
					handlerExpression = argument.expression
				} else {
					throw ValidationDiagnostic.extraneousHandler(node: Syntax(argument)).error
				}
			}
		}

		guard let handlerExpression else {
			throw ValidationDiagnostic.missingHandler(node: Syntax(attribute)).error
		}

		self.context = contextExpression
		self.mode = modeExpression
		self.handler = handlerExpression
	}

	var contextDescription: String {
		(context ?? ExprSyntax("self")).trimmedDescription
	}
}

private struct ValidationProperty {
	let declaration: VariableDeclSyntax
	let binding: PatternBindingSyntax
	let identifier: IdentifierPatternSyntax
	let type: TypeSyntax
	let initializerValue: ExprSyntax?

	init(from declaration: some DeclSyntaxProtocol) throws {
		guard let variable = declaration.as(VariableDeclSyntax.self) else {
			throw ValidationDiagnostic.requiresVariable(node: Syntax(declaration)).error
		}

		if variable.bindingSpecifier.tokenKind != .keyword(.var) {
			throw ValidationDiagnostic.requiresVariable(node: Syntax(variable.bindingSpecifier)).error
		}

		if variable.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class) }) {
			throw ValidationDiagnostic.unsupportedStatic(node: Syntax(variable)).error
		}

		if variable.modifiers.contains(where: { $0.name.tokenKind == .keyword(.lazy) }) {
			throw ValidationDiagnostic.unsupportedLazy(node: Syntax(variable)).error
		}

		guard let binding = variable.bindings.onlyElement else {
			throw ValidationDiagnostic.singleBinding(node: Syntax(variable)).error
		}

		if binding.accessorBlock != nil {
			throw ValidationDiagnostic.requiresStoredProperty(node: Syntax(binding)).error
		}

		guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
			throw ValidationDiagnostic.requiresIdentifier(node: Syntax(binding.pattern)).error
		}

		guard let type = binding.typeAnnotation?.type else {
			throw ValidationDiagnostic.requiresTypeAnnotation(node: Syntax(binding.pattern)).error
		}

		self.declaration = variable
		self.binding = binding
		self.identifier = identifier
		self.type = type.trimmed
		self.initializerValue = binding.initializer?.value
	}

	var storageName: String {
		"$\(identifier.identifier.text)"
	}

	var wrappedValueArgument: String? {
		initializerValue?.trimmedDescription
	}

	var valueType: TypeSyntax {
		type.removingOptional
	}

	var accessModifier: String {
		let allowed: Set<String> = ["public", "internal", "fileprivate", "private", "package", "open"]
		return declaration.modifiers
			.compactMap { modifier -> String? in
				let name = modifier.name.text
				return allowed.contains(name) ? modifier.trimmedDescription : nil
			}
			.joined(separator: " ")
	}

	func typeArguments(from attribute: AttributeSyntax) -> String {
		if let clause = attribute.genericArgumentClause {
			let description = clause.arguments.trimmedDescription
			if !description.isEmpty {
				return description
			}
		}

		return "\(valueType.trimmedDescription), _, _"
	}
}

private enum ValidationDiagnostic: DiagnosticMessage {
	case requiresVariable(node: Syntax)
	case singleBinding(node: Syntax)
	case requiresIdentifier(node: Syntax)
	case requiresTypeAnnotation(node: Syntax)
	case requiresStoredProperty(node: Syntax)
	case unsupportedArgument(String, node: Syntax)
	case duplicateArgument(String, node: Syntax)
	case extraneousHandler(node: Syntax)
	case missingHandler(node: Syntax)
	case unsupportedStatic(node: Syntax)
	case unsupportedLazy(node: Syntax)

	var message: String {
		switch self {
		case .requiresVariable:
			"@Validation can only be applied to variables."
		case .singleBinding:
			"@Validation can only be applied to a single stored property."
		case .requiresIdentifier:
			"@Validation requires an explicit identifier."
		case .requiresTypeAnnotation:
			"@Validation requires a type annotation."
		case .requiresStoredProperty:
			"@Validation can only be applied to stored properties."
		case .unsupportedArgument(let label, _):
			"Unsupported argument '\(label)'."
		case .duplicateArgument(let label, _):
			"Argument '\(label)' supplied multiple times."
		case .extraneousHandler:
			"Only a single handler closure is supported."
		case .missingHandler:
			"@Validation requires a handler closure."
		case .unsupportedStatic:
			"Static properties are not supported."
		case .unsupportedLazy:
			"Marking a @Validation property as lazy is not supported."
		}
	}

	var diagnosticID: MessageID {
		MessageID(domain: "ValidationMacro", id: identifier)
	}

	var severity: DiagnosticSeverity {
		.error
	}

	private var identifier: String {
		switch self {
		case .requiresVariable:
			"requiresVariable"
		case .singleBinding:
			"singleBinding"
		case .requiresIdentifier:
			"requiresIdentifier"
		case .requiresTypeAnnotation:
			"requiresTypeAnnotation"
		case .requiresStoredProperty:
			"requiresStored"
		case .unsupportedArgument:
			"unsupportedArgument"
		case .duplicateArgument:
			"duplicateArgument"
		case .extraneousHandler:
			"extraneousHandler"
		case .missingHandler:
			"missingHandler"
		case .unsupportedStatic:
			"unsupportedStatic"
		case .unsupportedLazy:
			"unsupportedLazy"
		}
	}
}

private extension ValidationDiagnostic {
	var node: Syntax {
		switch self {
		case .requiresVariable(let node),
			.singleBinding(let node),
			.requiresIdentifier(let node),
			.requiresTypeAnnotation(let node),
			.requiresStoredProperty(let node),
			.unsupportedArgument(_, let node),
			.duplicateArgument(_, let node),
			.extraneousHandler(let node),
			.missingHandler(let node),
			.unsupportedStatic(let node),
			.unsupportedLazy(let node):
			return node
		}
	}

	var error: DiagnosticsError {
		DiagnosticsError(diagnostics: [Diagnostic(node: node, message: self)])
	}
}

	private extension TypeSyntax {
	var removingOptional: TypeSyntax {
		if let optional = self.as(OptionalTypeSyntax.self) {
			return optional.wrappedType.removingOptional
		}
		if let implicitlyUnwrapped = self.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
			return implicitlyUnwrapped.wrappedType.removingOptional
		}
		if
			let identifier = self.as(IdentifierTypeSyntax.self),
			identifier.name.text == "Optional",
			let wrapped = identifier.genericArgumentClause?.arguments.first?.argument.as(TypeSyntax.self)
		{
			return wrapped.removingOptional
		}
		return self.trimmed
	}
}

private extension AttributeSyntax {
	var genericArgumentClause: GenericArgumentClauseSyntax? {
		if let identifier = attributeName.as(IdentifierTypeSyntax.self) {
			return identifier.genericArgumentClause
		}

		if let member = attributeName.as(MemberTypeSyntax.self) {
			return member.genericArgumentClause
		}

		return nil
	}
}

private extension PatternBindingListSyntax {
	var onlyElement: PatternBindingSyntax? {
		count == 1 ? first : nil
	}
}
