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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.20/JanusSDK.xcframework.zip",
      checksum: "bc53d04215919be012c0fe9abb67d9023f8f4089e6e1c968dca3a4b875761e75")
  ]
) 