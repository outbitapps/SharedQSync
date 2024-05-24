// swift-tools-version: 5.9
// This is a Skip (https://skip.tools) package,
// containing a Swift Package Manager project
// that will use the Skip build plugin to transpile the
// Swift Package, Sources, and Tests into an
// Android Gradle Project with Kotlin sources and JUnit tests.
import PackageDescription
import Foundation

// Set SKIP_ZERO=1 to build without Skip libraries
let zero = ProcessInfo.processInfo.environment["SKIP_ZERO"] != nil
let skipstone = !zero ? [Target.PluginUsage.plugin(name: "skipstone", package: "skip")] : []

let package = Package(
    name: "sharedqsync",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14), .tvOS(.v17), .watchOS(.v10), .macCatalyst(.v17)],
    products: [
        .library(name: "SharedQSync", targets: ["SharedQSync"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "0.8.28"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "0.0.0"),
        .package(url: "https://source.skip.tools/skip-firebase.git", from: "0.0.0"),
        .package(url: "git@github.com:paytontech/sharedqprotocol.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-docc", branch: "main")
    ],
    targets: [
        .target(name: "SharedQSync", dependencies: (zero ? [.product(name: "SharedQProtocol", package: "sharedqprotocol")] : [.product(name: "SharedQProtocol", package: "sharedqprotocol"), .product(name: "SkipFoundation", package: "skip-foundation")]), resources: [.process("Resources")]),
    ]
)
