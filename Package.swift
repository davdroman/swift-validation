// swift-tools-version: 6.1

import CompilerPluginSupport
import PackageDescription

let package = Package(
	name: "swift-validation",
	platforms: [
		.iOS(.v17),
		.macCatalyst(.v17),
		.macOS(.v14),
		.tvOS(.v17),
		.visionOS(.v1),
		.watchOS(.v10),
	],
	products: [
		.library(name: "Validation", targets: ["Validation"]),
	],
	traits: [
		"Dependencies",
	],
	targets: [
		.target(
			name: "Validation",
			dependencies: [
				"ValidationMacros",
				.product(name: "Builders", package: "swift-builders"),
				.product(name: "Dependencies", package: "swift-dependencies", condition: .when(traits: ["Dependencies"])),
				.product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
			]
		),
		.macro(
			name: "ValidationMacros",
			dependencies: [
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
				.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
			]
		),
		.testTarget(name: "ValidationTests", dependencies: [
			"Validation",
		]),
		.testTarget(
			name: "ValidationMacrosTests",
			dependencies: [
				"ValidationMacros",
				.product(name: "MacroTesting", package: "swift-macro-testing"),
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
			]
		),
	]
)

package.dependencies += [
	.package(url: "https://github.com/davdroman/swift-builders", from: "0.10.0"),
	.package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
	.package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.0"),
	.package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"603.0.0"),
	.package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.0.0"),
]

for target in package.targets {
	target.swiftSettings = target.swiftSettings ?? []
	target.swiftSettings? += [
		.enableUpcomingFeature("ExistentialAny"),
		.enableUpcomingFeature("InternalImportsByDefault"),
	]
}
