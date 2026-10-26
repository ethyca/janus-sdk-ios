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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.2.1/JanusSDK.xcframework.zip",
      checksum: "1cac9488962be30a5650053977444a7a91c119b2789870e72aabc5525d93f9f3")
  ]
) 