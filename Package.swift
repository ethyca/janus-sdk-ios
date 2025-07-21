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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.18/JanusSDK.xcframework.zip",
      checksum: "b83cdfaf513662e4a739c112cccc019c1c6a63fc4af33a01650c7331657c2ae3")
  ]
) 