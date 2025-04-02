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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.2/JanusSDK.xcframework.zip",
      checksum: "8911e99c96d834a4bfcfb9da8835f5efec14b1361e6be1af192f0304c6c59498")
  ]
) 