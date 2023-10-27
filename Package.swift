// swift-tools-version: 5.8

import PackageDescription

let package = Package(
	name: "swift-validation",
	platforms: [
		.iOS(.v13),
		.macOS(.v10_15),
		.tvOS(.v13),
		.watchOS(.v6),
	],
	products: [
		.library(name: "Validation", targets: ["Validation"]),
	],
	targets: [
		.target(
			name: "Validation",
			dependencies: [
				.product(name: "Builders", package: "swift-builders"),
				.product(name: "Validated", package: "swift-validated"),
			]
		),
		.testTarget(name: "ValidationTests", dependencies: [
			"Validation",
			.product(
				name: "ViewInspector",
				package: "ViewInspector",
				condition: .when(platforms: [.iOS, .macOS, .tvOS, .watchOS])
			),
		]),
	]
)

//#if !os(Linux)
//package.targets.append(contentsOf: [
//	.target(
//		name: "CombineValidation",
//		dependencies: [
////			"ValidationCore",
//		]
//	),
//	.target(
//		name: "ComposableValidation",
//		dependencies: [
//			.product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
////			"ValidationCore",
//		]
//	),
//])
//#endif

package.dependencies += [
	.package(url: "https://github.com/davdroman/swift-builders", from: "0.1.0"),
	.package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0"),
	.package(url: "https://github.com/nalexn/ViewInspector", from: "0.1.0"),
	.package(url: "https://github.com/pointfreeco/swift-validated", from: "0.1.0"),
]

//for target in package.targets where target.type != .system {
//	target.swiftSettings = target.swiftSettings ?? []
//	target.swiftSettings?.append(
//		.unsafeFlags([
//			"-Xfrontend", "-warn-concurrency",
//			"-Xfrontend", "-enable-actor-data-race-checks",
//		])
//	)
//}
