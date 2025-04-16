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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.6/JanusSDK.xcframework.zip",
      checksum: "42c2b81f169a3795e0ac88c526b6ffec81e6af113a27b5ef05901eba511e7544")
  ]
) 