// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "AHandGestureKit",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "AHandGestureKit",
            targets: ["AHandGestureKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AHandGestureKit",
            dependencies: [],
            path: "AHandGestureKit"
        )
    ]
)
