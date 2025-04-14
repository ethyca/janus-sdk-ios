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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.4/JanusSDK.xcframework.zip",
      checksum: "e55603224c1881d4c769d82dd93ab617b71e37c05992513af4d4fdd39a49d8f1")
  ]
) 