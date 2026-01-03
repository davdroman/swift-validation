import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct ValidationContextInitMacro: BodyMacro {
	static func expansion(
		of node: AttributeSyntax,
		providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
		in _: some MacroExpansionContext
	) throws -> [CodeBlockItemSyntax] {
		let existingStatements = Array(declaration.body?.statements ?? [])
		guard let properties = properties(from: node), !properties.isEmpty else {
			return existingStatements
		}

		var statements = existingStatements
		statements.append(
			contentsOf: properties.map { property in
				CodeBlockItemSyntax(stringLiteral: "$\(property).setContext(self)")
			}
		)
		return statements
	}
}

private func properties(from attribute: AttributeSyntax) -> [String]? {
	guard let arguments = attribute.arguments else { return nil }
	guard case let .argumentList(argumentList) = arguments else { return nil }

	let propertyArgument = argumentList.first { argument in
		argument.label?.text == "properties"
	} ?? argumentList.first

	guard let expression = propertyArgument?.expression else { return nil }
	guard let arrayExpression = expression.as(ArrayExprSyntax.self) else { return nil }

	var properties: [String] = []
	for element in arrayExpression.elements {
		guard let value = stringLiteralValue(from: element.expression) else { continue }
		properties.append(value)
	}
	return properties
}

private func stringLiteralValue(from expression: ExprSyntax) -> String? {
	if let literal = expression.as(StringLiteralExprSyntax.self) {
		return stringLiteralValue(from: literal)
	}

	if let literal = expression.as(SimpleStringLiteralExprSyntax.self) {
		return stringLiteralValue(from: literal)
	}

	return nil
}

private func stringLiteralValue(from literal: StringLiteralExprSyntax) -> String? {
	var value = ""
	for segment in literal.segments {
		switch segment {
		case let .stringSegment(segment):
			value += segment.content.text
		case .expressionSegment:
			return nil
		}
	}
	return value
}

private func stringLiteralValue(from literal: SimpleStringLiteralExprSyntax) -> String? {
	var value = ""
	for segment in literal.segments {
		value += segment.content.text
	}
	return value
}
