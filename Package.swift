// swift-tools-version: 6.4
// swiftlint:disable explicit_acl explicit_top_level_acl file_name

import PackageDescription

// Applied to the hand-written targets only. The generated target must keep
// the generator's bare (public) imports, so it gets no swiftSettings.
let swiftSettings: [SwiftSetting] = [
  .enableUpcomingFeature("InternalImportsByDefault"),
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("MemberImportVisibility"),
]

let package = Package(
  name: "ExpertHappiness",
  platforms: [
    .macOS(.v15)
  ],
  products: [
    .library(name: "ExpertHappiness", targets: ["ExpertHappiness"]),
    .library(name: "AppStoreConnectOpenAPI", targets: ["AppStoreConnectOpenAPI"]),
    .executable(name: "expert-happiness", targets: ["ExpertHappinessCLI"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.8.0"),
    .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.2.0"),
    .package(url: "https://github.com/apple/swift-http-types", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-crypto.git", "4.0.0"..<"6.0.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    .package(url: "https://github.com/1024jp/GzipSwift", from: "7.0.0"),
    .package(
      url: "https://github.com/apple/swift-configuration",
      from: "1.0.0",
      traits: ["CommandLineArguments"]
    ),
    .package(url: "https://github.com/brightdigit/ConfigKeyKit.git", from: "1.0.0-beta.3"),
  ],
  targets: [
    .target(
      name: "AppStoreConnectOpenAPI",
      dependencies: [
        .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
      ]
    ),
    .target(
      name: "ExpertHappiness",
      dependencies: [
        "AppStoreConnectOpenAPI",
        .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
        .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "Crypto", package: "swift-crypto"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "Gzip", package: "GzipSwift"),
      ],
      swiftSettings: swiftSettings
    ),
    .executableTarget(
      name: "ExpertHappinessCLI",
      dependencies: [
        "ExpertHappiness",
        .product(name: "Configuration", package: "swift-configuration"),
        .product(name: "ConfigKeyKit", package: "ConfigKeyKit"),
      ],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "ExpertHappinessTests",
      dependencies: [
        "ExpertHappiness",
        "AppStoreConnectOpenAPI",
        .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
        .product(name: "HTTPTypes", package: "swift-http-types"),
        .product(name: "Crypto", package: "swift-crypto"),
        .product(name: "Gzip", package: "GzipSwift"),
      ],
      resources: [.copy("Fixtures")],
      swiftSettings: swiftSettings
    ),
  ]
)

// swiftlint:enable explicit_acl explicit_top_level_acl file_name
