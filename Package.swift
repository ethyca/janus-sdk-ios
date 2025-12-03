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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.22/JanusSDK.xcframework.zip",
      checksum: "1dbb9f2e79bff44047a49560b37175d4f7d33169b109618e3a51d009b1741bf9")
  ]
) 