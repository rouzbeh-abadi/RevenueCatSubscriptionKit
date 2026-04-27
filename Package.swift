// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "RevenueCatSubscriptionKit",
                      platforms: [
                          .iOS(.v15),
                          .macOS(.v12),
                          .tvOS(.v15),
                          .watchOS(.v8),
                          .visionOS(.v1),
                      ],
                      products: [
                          .library(name: "RevenueCatSubscriptionKit",
                                   targets: ["RevenueCatSubscriptionKit"]),
                      ],
                      dependencies: [
                          .package(url: "https://github.com/RevenueCat/purchases-ios.git",
                                   from: "5.0.0"),
                      ],
                      targets: [
                          .target(name: "RevenueCatSubscriptionKit",
                                  dependencies: [
                                      .product(name: "RevenueCat", package: "purchases-ios"),
                                  ]),
                          .testTarget(name: "RevenueCatSubscriptionKitTests",
                                      dependencies: ["RevenueCatSubscriptionKit"]),
                      ],
                      swiftLanguageModes: [.v6])
