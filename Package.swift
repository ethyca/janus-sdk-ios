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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.11/JanusSDK.xcframework.zip",
      checksum: "430290bff276b1ff5f827e5f258be053eb04fb4b10f4d6a8ba15cf3cc787b2c7")
  ]
) 