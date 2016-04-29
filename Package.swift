import PackageDescription

let package = Package(
    name: "S4",
    dependencies: [
        .Package(url: "https://github.com/noppoman/C7.git", majorVersion: 0, minor: 5),
    ]
)
