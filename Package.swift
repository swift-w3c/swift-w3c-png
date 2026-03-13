// swift-tools-version: 6.2

import PackageDescription

// W3C PNG: Portable Network Graphics (Second Edition)
let package = Package(
    name: "swift-w3c-png",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(name: "W3C PNG", targets: ["W3C PNG"])
    ],
    dependencies: [
        .package(path: "../../swift-primitives/swift-standard-library-extensions"),
        .package(path: "../../swift-ietf/swift-rfc-1950")
    ],
    targets: [
        .target(
            name: "W3C PNG",
            dependencies: [
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "RFC 1950", package: "swift-rfc-1950")
            ]
        ),
        .testTarget(
            name: "W3C PNG Tests",
            dependencies: [
                "W3C PNG",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
}

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableExperimentalFeature("SuppressedAssociatedTypesWithDefaults"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
