// swift-tools-version: 5.7

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
			dependencies: [.product(name: "Validated", package: "swift-validated")]
		),
		.target(
			name: "ValidationTCA",
			dependencies: [.product(name: "ComposableArchitecture", package: "swift-composable-architecture")]
		),
		.testTarget(name: "ValidationTests", dependencies: ["Validation"]),
	]
)

package.dependencies += [
	.package(url: "https://github.com/pointfreeco/swift-validated", from: "0.1.0"),
	.package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0"),
]
