import PackageDescription

let package = Package(
    name: "Multipart",
    dependencies: [
        // Core extensions, type-aliases, and functions that facilitate common tasks
        .Package(url: "https://github.com/vapor/core.git", majorVersion: 1)
    ]
)
