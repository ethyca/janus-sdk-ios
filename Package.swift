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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.12/JanusSDK.xcframework.zip",
      checksum: "8eb7ff1c6dd0cd1039c5fd6ca52cec0739eb06da062fa60d268c5eb897fd4fa4")
  ]
) 