// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "SeifertAusgaben",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "SeifertAusgaben", targets: ["SeifertAusgaben"])
  ],
  targets: [
    .executableTarget(
      name: "SeifertAusgaben",
      resources: [.copy("Resources/Logo_seifert-it.jpg")]
    ),
    .testTarget(
      name: "SeifertAusgabenTests",
      dependencies: ["SeifertAusgaben"]
    ),
  ]
)
