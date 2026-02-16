// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "VoiceToText",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "VoiceToText",
            dependencies: ["whisper"],
            path: "Sources/VoiceToText",
            exclude: ["Resources/Info.plist"],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist", "-Xlinker", "Sources/VoiceToText/Resources/Info.plist"])
            ]
        ),
        .binaryTarget(
            name: "whisper",
            path: "Frameworks/whisper.xcframework"
        )
    ]
)
