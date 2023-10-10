// swift-tools-version: 5.7

import PackageDescription

let package = Package(
	name: "swift-validation",
	products: [
		.library(name: "Validation", targets: ["Validation"]),
	],
	targets: [
		.target(name: "Validation"),
		.testTarget(name: "ValidationTests", dependencies: ["Validation"]),
	]
)
