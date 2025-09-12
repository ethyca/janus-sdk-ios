// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "JanusSDK",
  platforms: [
    .iOS(.v14)
  ],
  products: [
    .library(
      name: "JanusSDK",
      targets: ["JanusSDK"])
  ],
  targets: [
    .binaryTarget(
      name: "JanusSDK",
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.19/JanusSDK.xcframework.zip",
      checksum: "48e7fc14666bd76041271685b2afb836aaaf5457208502691d7c83c107db9a15")
  ]
) 