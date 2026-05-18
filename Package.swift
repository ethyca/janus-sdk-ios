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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.26/JanusSDK.xcframework.zip",
      checksum: "07f6a7d9cb64ffcc6c1d8b3a75fb9d2da70833c71027e49a7e83c22fff0179a2")
  ]
) 