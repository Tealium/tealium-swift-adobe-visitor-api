// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "TealiumAdobeVisitorAPI",
    platforms: [ .iOS(.v12), .macOS(.v10_14), .tvOS(.v12), .watchOS(.v4) ],
    products: [
        .library(
            name: "TealiumAdobeVisitorAPI",
            type: .static,
            targets: ["TealiumAdobeVisitorAPI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Tealium/tealium-swift", .upToNextMajor(from: "2.12.0"))
    ],
    targets: [
        .target(
            name: "TealiumAdobeVisitorAPI",
            dependencies: ["TealiumCore"],
            path: "TealiumAdobeVisitorAPI/"
        ),
    ]
)
