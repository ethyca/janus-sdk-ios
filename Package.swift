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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.7/JanusSDK.xcframework.zip",
      checksum: "a505408d81398a88d88af6b5eca0730f964649e415f3c31c8f61278286c7f4d6")
  ]
) 