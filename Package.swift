// swift-tools-version: 5.9

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
		.target(
			name: "Validation",
			dependencies: [
				.product(name: "Builders", package: "swift-builders"),
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "NonEmpty", package: "swift-nonempty"),
			]
		),
		.testTarget(name: "ValidationTests", dependencies: [
			"Validation",
		]),
	]
)

package.dependencies += [
	.package(url: "https://github.com/davdroman/swift-builders", from: "0.6.0"),
//	.package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0"),
	.package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
	.package(url: "https://github.com/pointfreeco/swift-nonempty", from: "0.4.0"),
]

//for target in package.targets where target.type != .system {
//	target.swiftSettings = target.swiftSettings ?? []
//	target.swiftSettings?.append(contentsOf: [
//		.enableUpcomingFeature("ConciseMagicFile"),
//		.enableUpcomingFeature("ExistentialAny"),
//		.enableUpcomingFeature("StrictConcurrency"),
//		.enableUpcomingFeature("ImplicitOpenExistentials"),
//		.enableUpcomingFeature("BareSlashRegexLiterals"),
//	])
//}
