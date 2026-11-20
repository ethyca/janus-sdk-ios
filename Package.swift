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
      url: "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/1.4.1/JanusSDK.xcframework.zip",
      checksum: "71988b596c32dec48da9f314c216485ad8f3f9dfd77526bbf9666aa3cf9c8825")
  ]
) 