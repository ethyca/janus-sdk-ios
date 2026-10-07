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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.1.0/JanusSDK.xcframework.zip",
      checksum: "8d52e2902b553d9bcaae8fde3a455f2c77062e5c0917587e0c3ad5833800bc78")
  ]
) 