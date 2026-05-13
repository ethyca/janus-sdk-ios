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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.25/JanusSDK.xcframework.zip",
      checksum: "869ba29fbca47db41dd3b2dd1bdd685a780b1a004d5708bc6fa32a0fce4070a8")
  ]
) 