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
        .visionOS(.v26),
    ],
    products: [
        .library(name: "W3C PNG", targets: ["W3C PNG"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-standard-library-extensions.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-standards/swift-rfc-1950.git", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "W3C PNG",
            dependencies: [
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "RFC 1950", package: "swift-rfc-1950"),
            ]
        ),
        .testTarget(
            name: "W3C PNG".tests,
            dependencies: ["W3C PNG"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
}

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
    ]
}
