// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWCameraPickerController",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(name: "WWCameraPickerController", targets: ["WWCameraPickerController"])
    ],
    dependencies: [],
    targets: [
        .target(name: "WWCameraPickerController",  resources: [.copy("Privacy")]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
