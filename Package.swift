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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.13/JanusSDK.xcframework.zip",
      checksum: "03b1b124220274efaf5a5b5ce82fa19d4abc5e05a15a2a6c14026bf88a079409")
  ]
) 