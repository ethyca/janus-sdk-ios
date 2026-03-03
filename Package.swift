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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.23/JanusSDK.xcframework.zip",
      checksum: "b64dbe94d2b3214eba9243445152ac939a01724ef45fc55c7a4c8058f810fbe0")
  ]
) 