// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "TealiumAdobeVisitorAPI",
    platforms: [ .iOS(.v9), .macOS(.v10_11), .tvOS(.v9), .watchOS(.v3) ],
    products: [
        .library(
            name: "TealiumAdobeVisitorAPI",
            type: .static,
            targets: ["TealiumAdobeVisitorAPI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Tealium/tealium-swift", .upToNextMajor(from: "2.8.0"))
    ],
    targets: [
        .target(
            name: "TealiumAdobeVisitorAPI",
            dependencies: ["TealiumCore"],
            path: "TealiumAdobeVisitorAPI/TealiumAdobeVisitorAPI/"
        ),
    ]
)
