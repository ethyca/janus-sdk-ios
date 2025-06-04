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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.0.13/JanusSDK.xcframework.zip",
      checksum: "48e10b87bc68156aa2be73814a628512aad8deae3a8d40fff75b076f8dd7c0fd")
  ]
) 