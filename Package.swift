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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.4.2/JanusSDK.xcframework.zip",
      checksum: "c249be2e91d0dd0db4a2b05eaa3ae58e5af8a46c6cd8e7867271d818778abd4c")
  ]
) 