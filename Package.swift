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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.24/JanusSDK.xcframework.zip",
      checksum: "1ed838cb2de4eabded12b4353179b1e255225d5e09d38ccced715f9eb6bc59d7")
  ]
) 