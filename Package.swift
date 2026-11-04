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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.3.0/JanusSDK.xcframework.zip",
      checksum: "7d6c1c8cbbfd9ed5a491c88152d6216694045b07e4e917c2fafbcaf65d367bc3")
  ]
) 