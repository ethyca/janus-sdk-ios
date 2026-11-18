// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "JanusSDK",
  platforms: [
    .iOS(.v15)
  ],
  products: [
    .library(
      name: "JanusSDK",
      targets: ["JanusSDK"])
  ],
  targets: [
    .binaryTarget(
      name: "JanusSDK",
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.4.0/JanusSDK.xcframework.zip",
      checksum: "d34a63cb6167a37a8fe27af6c2488f33abc8b52f1dca51324f63a87058d88770")
  ]
) 