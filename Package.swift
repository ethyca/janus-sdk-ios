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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.14/JanusSDK.xcframework.zip",
      checksum: "20b9acb03fb9325e12b3065f506f8d47de75a0c4ec7decb15909e88a06fec550")
  ]
) 