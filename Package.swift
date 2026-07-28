// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Chirpet",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Chirpet",
            path: "Sources/Chirpet"
        )
    ]
)
