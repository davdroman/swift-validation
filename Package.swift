// swift-tools-version: 6.0

import CompilerPluginSupport
import PackageDescription

let package = Package(
	name: "swift-validation",
	platforms: [
		.iOS(.v17),
		.macOS(.v14),
		.tvOS(.v17),
		.watchOS(.v10),
	],
	products: [
		.library(name: "Validation", targets: ["Validation"]),
	],
	targets: [
		.macro(
			name: "ValidationMacro",
			dependencies: [
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
				.product(name: "SwiftDiagnostics", package: "swift-syntax"),
				.product(name: "SwiftSyntax", package: "swift-syntax"),
				.product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
				.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
			]
		),
		.target(
			name: "Validation",
			dependencies: [
				.product(name: "Builders", package: "swift-builders"),
				.product(name: "Dependencies", package: "swift-dependencies"),
				"ValidationMacro",
			]
		),
		.testTarget(
			name: "ValidationTests",
			dependencies: [
				"Validation",
			]
		),
		.testTarget(
			name: "ValidationMacroTests",
			dependencies: [
				"ValidationMacro",
				.product(name: "MacroTesting", package: "swift-macro-testing"),
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
			]
		),
	]
)

package.dependencies += [
	.package(url: "https://github.com/davdroman/swift-builders", from: "0.1.0"),
	.package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
	.package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.0"),
	.package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"603.0.0"),
]

for target in package.targets {
	target.swiftSettings = target.swiftSettings ?? []
	target.swiftSettings? += [
		.enableUpcomingFeature("ExistentialAny"),
		.enableUpcomingFeature("InternalImportsByDefault"),
	]
}
