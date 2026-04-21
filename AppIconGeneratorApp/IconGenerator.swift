import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum IconGeneratorError: Error, LocalizedError {
    case sourceImageLoadFailed
    case sourceImageTooSmall(required: Int, actual: Int)
    case resizeFailed(target: Int)
    case pngWriteFailed(path: String)

    var errorDescription: String? {
        switch self {
        case .sourceImageLoadFailed:
            return "원본 이미지를 불러올 수 없습니다."
        case let .sourceImageTooSmall(required, actual):
            return "원본 이미지가 너무 작습니다. 최소 \(required)x\(required) 이상이 필요합니다. (현재: \(actual)x\(actual))"
        case let .resizeFailed(target):
            return "\(target)x\(target) 리사이즈에 실패했습니다."
        case let .pngWriteFailed(path):
            return "PNG 저장에 실패했습니다: \(path)"
        }
    }
}

struct IconGenerator {
    func generate(
        sourceURL: URL,
        outputDirectory: URL,
        includeIPhone: Bool,
        includeIPad: Bool,
        includeMacOS: Bool,
        includeWatchOS: Bool,
        includeAndroid: Bool,
        androidBaseFileName: String,
        androidTargetRoot: String
    ) throws -> [String] {
        guard let source = loadCGImage(from: sourceURL) else {
            throw IconGeneratorError.sourceImageLoadFailed
        }

        let minSide = min(source.width, source.height)
        guard minSide >= IconSpecs.maxRequiredSourceSize else {
            throw IconGeneratorError.sourceImageTooSmall(
                required: IconSpecs.maxRequiredSourceSize,
                actual: minSide
            )
        }

        var logs: [String] = []

        if includeIPhone {
            try generateAppleAssets(
                source: source,
                outputDirectory: outputDirectory,
                platform: .iPhone,
                specs: IconSpecs.iPhone,
                logs: &logs
            )
        }

        if includeIPad {
            try generateAppleAssets(
                source: source,
                outputDirectory: outputDirectory,
                platform: .iPad,
                specs: IconSpecs.iPad,
                logs: &logs
            )
        }

        if includeMacOS {
            try generateAppleAssets(
                source: source,
                outputDirectory: outputDirectory,
                platform: .macOS,
                specs: IconSpecs.macOS,
                logs: &logs
            )
        }

        if includeWatchOS {
            try generateAppleAssets(
                source: source,
                outputDirectory: outputDirectory,
                platform: .watchOS,
                specs: IconSpecs.watchOS,
                logs: &logs
            )
        }

        if includeAndroid {
            let androidRoot = outputDirectory.appendingPathComponent("Android", isDirectory: true)
            try generateAndroidAssets(
                source: source,
                outputRoot: androidRoot,
                baseFileName: androidBaseFileName,
                targetRoot: androidTargetRoot,
                logs: &logs
            )
        }

        if !includeIPhone && !includeIPad && !includeMacOS && !includeWatchOS && !includeAndroid {
            logs.append("선택된 플랫폼이 없어 파일을 생성하지 않았습니다.")
        }

        return logs
    }

    private func generateAppleAssets(
        source: CGImage,
        outputDirectory: URL,
        platform: ApplePlatform,
        specs: [AppleIconSpec],
        logs: inout [String]
    ) throws {
        let fileManager = FileManager.default
        let outputRoot = outputDirectory.appendingPathComponent(platform.folderName, isDirectory: true)
        let appIconSet = outputRoot
            .appendingPathComponent("AppIcon.appiconset", isDirectory: true)

        try fileManager.createDirectory(at: appIconSet, withIntermediateDirectories: true)

        var imageEntries: [[String: String]] = []

        for spec in specs {
            guard let resized = resizedImage(from: source, to: spec.pixelSize) else {
                throw IconGeneratorError.resizeFailed(target: spec.pixelSize)
            }

            let fileURL = appIconSet.appendingPathComponent(spec.fileName)
            try writePNG(resized, to: fileURL)

            imageEntries.append([
                "idiom": spec.idiom,
                "size": spec.sizeText,
                "scale": spec.scaleText,
                "filename": spec.fileName
            ])
        }

        let contents: [String: Any] = [
            "images": imageEntries,
            "info": [
                "version": 1,
                "author": "xcode"
            ]
        ]

        let jsonURL = appIconSet.appendingPathComponent("Contents.json")
        let jsonData = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
        try jsonData.write(to: jsonURL)

        logs.append("\(platform.folderName) 아이콘 생성 완료: \(appIconSet.path)")
    }

    private func generateAndroidAssets(
        source: CGImage,
        outputRoot: URL,
        baseFileName: String,
        targetRoot: String,
        logs: inout [String]
    ) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: outputRoot, withIntermediateDirectories: true)

        for spec in IconSpecs.android {
            guard let resized = resizedImage(from: source, to: spec.pixelSize) else {
                throw IconGeneratorError.resizeFailed(target: spec.pixelSize)
            }

            let folderName = spec.folder.replacingOccurrences(of: "mipmap", with: targetRoot)
            let folderURL = outputRoot.appendingPathComponent(folderName, isDirectory: true)
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)

            let launcherURL = folderURL.appendingPathComponent("\(baseFileName).png")
            let roundURL = folderURL.appendingPathComponent("\(baseFileName)_round.png")

            try writePNG(resized, to: launcherURL)
            try writePNG(resized, to: roundURL)
        }

        let playStoreFolder = outputRoot.appendingPathComponent("playstore", isDirectory: true)
        try fileManager.createDirectory(at: playStoreFolder, withIntermediateDirectories: true)

        guard let playStoreImage = resizedImage(from: source, to: IconSpecs.androidPlayStoreSize) else {
            throw IconGeneratorError.resizeFailed(target: IconSpecs.androidPlayStoreSize)
        }

        let playStoreURL = playStoreFolder.appendingPathComponent("\(baseFileName)-playstore.png")
        try writePNG(playStoreImage, to: playStoreURL)

        logs.append("Android 아이콘 생성 완료: \(outputRoot.path)")
    }

    private func loadCGImage(from url: URL) -> CGImage? {
        guard let nsImage = NSImage(contentsOf: url) else {
            return nil
        }

        var rect = CGRect(origin: .zero, size: nsImage.size)
        return nsImage.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }

    private func resizedImage(from source: CGImage, to size: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .high
        context.draw(source, in: CGRect(x: 0, y: 0, width: size, height: size))

        return context.makeImage()
    }

    private func writePNG(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw IconGeneratorError.pngWriteFailed(path: url.path)
        }

        CGImageDestinationAddImage(destination, image, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw IconGeneratorError.pngWriteFailed(path: url.path)
        }
    }
}
