// swift-tools-version: 6.1

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
	traits: [
		"Dependencies",
	],
	targets: [
		.target(
			name: "Validation",
			dependencies: [
				.product(name: "Builders", package: "swift-builders"),
				.product(name: "Dependencies", package: "swift-dependencies", condition: .when(traits: ["Dependencies"])),
			]
		),
		.testTarget(name: "ValidationTests", dependencies: [
			"Validation",
		]),
	]
)

package.dependencies += [
	.package(url: "https://github.com/davdroman/swift-builders", from: "0.1.0"),
	.package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
]

for target in package.targets {
	target.swiftSettings = target.swiftSettings ?? []
	target.swiftSettings? += [
		.enableUpcomingFeature("ExistentialAny"),
		.enableUpcomingFeature("InternalImportsByDefault"),
	]
}
