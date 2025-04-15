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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.5/JanusSDK.xcframework.zip",
      checksum: "23239e203c8c3e20191b896a96ebd26a26dfaf78828cd6488c0e1a5a9db6fc95")
  ]
) 