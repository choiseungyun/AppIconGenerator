import Foundation

enum ApplePlatform: String, CaseIterable {
    case iPhone
    case iPad
    case macOS
    case watchOS

    var folderName: String {
        rawValue
    }
}

struct AppleIconSpec {
    let idiom: String
    let pointSize: Double
    let scale: Int
    let fileNamePrefix: String

    var pixelSize: Int {
        Int((pointSize * Double(scale)).rounded())
    }

    var sizeText: String {
        "\(pointSize)x\(pointSize)"
    }

    var scaleText: String {
        "\(scale)x"
    }

    var fileName: String {
        "\(fileNamePrefix)-\(pointSize)x\(pointSize)@\(scale)x.png"
    }
}

struct AndroidIconSpec {
    let folder: String
    let pixelSize: Int
}

enum IconSpecs {
    static let iPhone: [AppleIconSpec] = [
        .init(idiom: "iphone", pointSize: 20, scale: 2, fileNamePrefix: "iphone"),
        .init(idiom: "iphone", pointSize: 20, scale: 3, fileNamePrefix: "iphone"),
        .init(idiom: "iphone", pointSize: 29, scale: 2, fileNamePrefix: "iphone"),
        .init(idiom: "iphone", pointSize: 29, scale: 3, fileNamePrefix: "iphone"),
        .init(idiom: "iphone", pointSize: 40, scale: 2, fileNamePrefix: "iphone"),
        .init(idiom: "iphone", pointSize: 40, scale: 3, fileNamePrefix: "iphone"),
        .init(idiom: "iphone", pointSize: 60, scale: 2, fileNamePrefix: "iphone"),
        .init(idiom: "iphone", pointSize: 60, scale: 3, fileNamePrefix: "iphone")
    ]

    static let iPad: [AppleIconSpec] = [
        .init(idiom: "ipad", pointSize: 20, scale: 1, fileNamePrefix: "ipad"),
        .init(idiom: "ipad", pointSize: 20, scale: 2, fileNamePrefix: "ipad"),
        .init(idiom: "ipad", pointSize: 29, scale: 1, fileNamePrefix: "ipad"),
        .init(idiom: "ipad", pointSize: 29, scale: 2, fileNamePrefix: "ipad"),
        .init(idiom: "ipad", pointSize: 40, scale: 1, fileNamePrefix: "ipad"),
        .init(idiom: "ipad", pointSize: 40, scale: 2, fileNamePrefix: "ipad"),
        .init(idiom: "ipad", pointSize: 76, scale: 1, fileNamePrefix: "ipad"),
        .init(idiom: "ipad", pointSize: 76, scale: 2, fileNamePrefix: "ipad"),
        .init(idiom: "ipad", pointSize: 83.5, scale: 2, fileNamePrefix: "ipad")
    ]

    static let macOS: [AppleIconSpec] = [
        .init(idiom: "mac", pointSize: 16, scale: 1, fileNamePrefix: "macos"),
        .init(idiom: "mac", pointSize: 16, scale: 2, fileNamePrefix: "macos"),
        .init(idiom: "mac", pointSize: 32, scale: 1, fileNamePrefix: "macos"),
        .init(idiom: "mac", pointSize: 32, scale: 2, fileNamePrefix: "macos"),
        .init(idiom: "mac", pointSize: 128, scale: 1, fileNamePrefix: "macos"),
        .init(idiom: "mac", pointSize: 128, scale: 2, fileNamePrefix: "macos"),
        .init(idiom: "mac", pointSize: 256, scale: 1, fileNamePrefix: "macos"),
        .init(idiom: "mac", pointSize: 256, scale: 2, fileNamePrefix: "macos"),
        .init(idiom: "mac", pointSize: 512, scale: 1, fileNamePrefix: "macos"),
        .init(idiom: "mac", pointSize: 512, scale: 2, fileNamePrefix: "macos")
    ]

    static let watchOS: [AppleIconSpec] = [
        .init(idiom: "watch", pointSize: 24, scale: 2, fileNamePrefix: "watchos"),
        .init(idiom: "watch", pointSize: 27.5, scale: 2, fileNamePrefix: "watchos"),
        .init(idiom: "watch", pointSize: 29, scale: 2, fileNamePrefix: "watchos"),
        .init(idiom: "watch", pointSize: 40, scale: 2, fileNamePrefix: "watchos"),
        .init(idiom: "watch", pointSize: 44, scale: 2, fileNamePrefix: "watchos"),
        .init(idiom: "watch", pointSize: 86, scale: 2, fileNamePrefix: "watchos"),
        .init(idiom: "watch", pointSize: 98, scale: 2, fileNamePrefix: "watchos"),
        .init(idiom: "watch", pointSize: 108, scale: 2, fileNamePrefix: "watchos")
    ]

    static let android: [AndroidIconSpec] = [
        .init(folder: "mipmap-mdpi", pixelSize: 48),
        .init(folder: "mipmap-hdpi", pixelSize: 72),
        .init(folder: "mipmap-xhdpi", pixelSize: 96),
        .init(folder: "mipmap-xxhdpi", pixelSize: 144),
        .init(folder: "mipmap-xxxhdpi", pixelSize: 192)
    ]

    static let androidPlayStoreSize = 512
    static let maxRequiredSourceSize = 1024
}
