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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.15/JanusSDK.xcframework.zip",
      checksum: "2875de9d1ec60d0fb28813e32476204f213d5e310b2c9ecfe4f48ec456bfb16f")
  ]
) 