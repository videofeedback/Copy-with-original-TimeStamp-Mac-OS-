// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CopyWithCreationDate",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "CopyWithCreationDate", targets: ["CopyWithCreationDate"])
    ],
    targets: [
        .executableTarget(
            name: "CopyWithCreationDate",
            path: "Sources"
        ),
        .testTarget(
            name: "CopyWithCreationDateTests",
            dependencies: ["CopyWithCreationDate"],
            path: "Tests/CopyWithCreationDateTests"
        )
    ]
)
