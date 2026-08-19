// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "eudamed-public",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "EudamedCore",
            targets: ["EudamedRest"]
        ),
        .library(
            name: "EudamedClient",
            targets: ["EudamedClient"]
        ),
        .library(
            name: "EudamedServer",
            targets: ["EudamedServer"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-http-types", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "EudamedRest",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
            ]
        ),
        .target(
            name: "EudamedClient",
            dependencies: ["EudamedRest"]
        ),
        .target(
            name: "EudamedServer",
            dependencies: [
                "EudamedRest",
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
            ]
        ),
        .testTarget(
            name: "EudamedRestTests",
            dependencies: [
                "EudamedRest",
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ]
        ),
        .testTarget(
            name: "EudamedClientTests",
            dependencies: [
                "EudamedClient",
                "EudamedRest",
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "HTTPTypes", package: "swift-http-types"),
            ]
        ),
    ]
)
