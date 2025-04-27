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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.8/JanusSDK.xcframework.zip",
      checksum: "871e624ec9a74f951bd63062eaf575ac6500d52cd3c91d6320e7a51f49b4593b")
  ]
) 