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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.1/JanusSDK.xcframework.zip",
      checksum: "40042c2dd32493bec39f1ff5365ddb9d4e9f009be28f7b108b6fc35d12c126f4")
  ]
) 