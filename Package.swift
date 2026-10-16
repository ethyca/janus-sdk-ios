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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.2.0/JanusSDK.xcframework.zip",
      checksum: "01a70ea24937dacce7816de040fcb2c5a8a599848053085435be57eebd6470db")
  ]
) 