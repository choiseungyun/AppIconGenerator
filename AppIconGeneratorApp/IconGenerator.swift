import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum IconGeneratorError: Error, LocalizedError {
    case sourceImageLoadFailed
    case sourceImageTooSmall(required: Int, actual: Int)
    case resizeFailed(target: Int)
    case pngWriteFailed(path: String)
    case canvasCreationFailed(width: Int, height: Int)

    var errorDescription: String? {
        switch self {
        case .sourceImageLoadFailed:
            return AppLanguage.localized("원본 이미지를 불러올 수 없습니다.")
        case let .sourceImageTooSmall(required, actual):
            let template = AppLanguage.localized("원본 이미지가 너무 작습니다. 최소 %ldx%ld 이상이 필요합니다. (현재: %ldx%ld)")
            return String(format: template, required, required, actual, actual)
        case let .resizeFailed(target):
            let template = AppLanguage.localized("%ldx%ld 리사이즈에 실패했습니다.")
            return String(format: template, target, target)
        case let .pngWriteFailed(path):
            let template = AppLanguage.localized("PNG 저장에 실패했습니다: %@")
            return String(format: template, path)
        case let .canvasCreationFailed(width, height):
            let template = AppLanguage.localized("%ldx%ld 캔버스 생성에 실패했습니다.")
            return String(format: template, width, height)
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
        includeIOSUniversal: Bool,
        iOSUniversalDarkURL: URL?,
        iOSUniversalTintedURL: URL?,
        includeAndroid: Bool,
        androidBaseFileName: String,
        androidTargetRoot: String
    ) throws -> [GenerationLogEntry] {
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

        var logs: [GenerationLogEntry] = []

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

        if includeIOSUniversal {
            try generateSingleSizeAppleAssets(
                source: source,
                darkSourceURL: iOSUniversalDarkURL,
                tintedSourceURL: iOSUniversalTintedURL,
                outputDirectory: outputDirectory,
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

        if !includeIPhone && !includeIPad && !includeMacOS && !includeWatchOS && !includeIOSUniversal && !includeAndroid {
            logs.append(GenerationLogEntry(
                kind: .warning,
                message: AppLanguage.localized("선택된 플랫폼이 없어 파일을 생성하지 않았습니다."),
                path: nil
            ))
        }

        return logs
    }

    private func generateSingleSizeAppleAssets(
        source: CGImage,
        darkSourceURL: URL?,
        tintedSourceURL: URL?,
        outputDirectory: URL,
        logs: inout [GenerationLogEntry]
    ) throws {
        let fileManager = FileManager.default
        let outputRoot = outputDirectory.appendingPathComponent(ApplePlatform.iOS.folderName, isDirectory: true)
        let appIconSet = outputRoot.appendingPathComponent("AppIcon.appiconset", isDirectory: true)

        try fileManager.createDirectory(at: appIconSet, withIntermediateDirectories: true)

        guard let resized = resizedOpaqueImage(from: source, to: IconSpecs.iOSUniversalPixelSize) else {
            throw IconGeneratorError.resizeFailed(target: IconSpecs.iOSUniversalPixelSize)
        }

        let fileURL = appIconSet.appendingPathComponent(IconSpecs.iOSUniversalFileName)
        try writePNG(resized, to: fileURL)

        var imageEntries: [[String: Any]] = [[
            "filename": IconSpecs.iOSUniversalFileName,
            "idiom": "universal",
            "platform": "ios",
            "size": "\(IconSpecs.iOSUniversalPixelSize)x\(IconSpecs.iOSUniversalPixelSize)"
        ]]

        var includedAppearances: [String] = []

        if let darkSourceURL, let darkSource = loadCGImage(from: darkSourceURL) {
            let darkFileName = "AppIcon-1024-dark.png"

            // iOS 18 Dark 아이콘은 투명도를 허용하지 않으므로 검정 배경으로 flatten한다.
            guard let darkResized = resizedOpaqueImage(
                from: darkSource,
                to: IconSpecs.iOSUniversalPixelSize,
                background: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
            ) else {
                throw IconGeneratorError.resizeFailed(target: IconSpecs.iOSUniversalPixelSize)
            }

            try writePNG(darkResized, to: appIconSet.appendingPathComponent(darkFileName))
            imageEntries.append([
                "filename": darkFileName,
                "idiom": "universal",
                "platform": "ios",
                "size": "\(IconSpecs.iOSUniversalPixelSize)x\(IconSpecs.iOSUniversalPixelSize)",
                "appearances": [["appearance": "luminosity", "value": "dark"]]
            ])
            includedAppearances.append("Dark")
        }

        if let tintedSourceURL, let tintedSource = loadCGImage(from: tintedSourceURL) {
            let tintedFileName = "AppIcon-1024-tinted.png"

            // Tinted 아이콘은 시스템이 사용자가 고른 색으로 입히므로 흑백(grayscale)으로 제공해야 한다.
            guard let tintedResized = resizedGrayscaleOpaqueImage(from: tintedSource, to: IconSpecs.iOSUniversalPixelSize) else {
                throw IconGeneratorError.resizeFailed(target: IconSpecs.iOSUniversalPixelSize)
            }

            try writePNG(tintedResized, to: appIconSet.appendingPathComponent(tintedFileName))
            imageEntries.append([
                "filename": tintedFileName,
                "idiom": "universal",
                "platform": "ios",
                "size": "\(IconSpecs.iOSUniversalPixelSize)x\(IconSpecs.iOSUniversalPixelSize)",
                "appearances": [["appearance": "luminosity", "value": "tinted"]]
            ])
            includedAppearances.append("Tinted")
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

        let message: String
        if includedAppearances.isEmpty {
            message = AppLanguage.localized("iOS 아이콘 생성 완료 (Single Size, Xcode 14+)")
        } else {
            let suffix = includedAppearances.joined(separator: "/")
            let template = AppLanguage.localized("iOS 아이콘 생성 완료 (Single Size, Xcode 14+, %@ 포함)")
            message = String(format: template, suffix)
        }
        logs.append(GenerationLogEntry(kind: .iosUniversalIcon, message: message, path: appIconSet.path))
        logs.append(GenerationLogEntry(
            kind: .notice,
            message: AppLanguage.localized("주의: Xcode Build Settings에서 'Include All App Icon Assets'를 YES로 설정해야 나머지 사이즈가 자동 생성됩니다."),
            path: nil
        ))
    }

    private func generateAppleAssets(
        source: CGImage,
        outputDirectory: URL,
        platform: ApplePlatform,
        specs: [AppleIconSpec],
        logs: inout [GenerationLogEntry]
    ) throws {
        let fileManager = FileManager.default
        let outputRoot = outputDirectory.appendingPathComponent(platform.folderName, isDirectory: true)
        let appIconSet = outputRoot
            .appendingPathComponent("AppIcon.appiconset", isDirectory: true)

        try fileManager.createDirectory(at: appIconSet, withIntermediateDirectories: true)

        var imageEntries: [[String: String]] = []

        for spec in specs {
            let resizedOrNil = spec.flattensAlpha
                ? resizedOpaqueImage(from: source, to: spec.pixelSize)
                : resizedImage(from: source, to: spec.pixelSize)

            guard let resized = resizedOrNil else {
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

        let template = AppLanguage.localized("%@ 아이콘 생성 완료")
        logs.append(GenerationLogEntry(
            kind: .appleIconSet(platform),
            message: String(format: template, platform.folderName),
            path: appIconSet.path
        ))
    }

    private func generateAndroidAssets(
        source: CGImage,
        outputRoot: URL,
        baseFileName: String,
        targetRoot: String,
        logs: inout [GenerationLogEntry]
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

        logs.append(GenerationLogEntry(
            kind: .androidIconSet,
            message: AppLanguage.localized("Android 아이콘 생성 완료"),
            path: outputRoot.path
        ))

        try generateAndroidAdaptiveAssets(
            source: source,
            outputRoot: outputRoot,
            baseFileName: baseFileName,
            targetRoot: targetRoot,
            logs: &logs
        )
    }

    private func generateAndroidAdaptiveAssets(
        source: CGImage,
        outputRoot: URL,
        baseFileName: String,
        targetRoot: String,
        logs: inout [GenerationLogEntry]
    ) throws {
        let fileManager = FileManager.default

        for spec in IconSpecs.androidAdaptiveForeground {
            guard let foreground = resizedForegroundImage(from: source, canvasSize: spec.pixelSize) else {
                throw IconGeneratorError.resizeFailed(target: spec.pixelSize)
            }

            let folderName = spec.folder.replacingOccurrences(of: "mipmap", with: targetRoot)
            let folderURL = outputRoot.appendingPathComponent(folderName, isDirectory: true)
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)

            let foregroundURL = folderURL.appendingPathComponent("\(baseFileName)_foreground.png")
            try writePNG(foreground, to: foregroundURL)
        }

        let anydpiURL = outputRoot.appendingPathComponent("mipmap-anydpi-v26", isDirectory: true)
        try fileManager.createDirectory(at: anydpiURL, withIntermediateDirectories: true)

        let adaptiveXML = """
        <?xml version="1.0" encoding="utf-8"?>
        <adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
            <background android:drawable="@color/\(baseFileName)_background"/>
            <foreground android:drawable="@mipmap/\(baseFileName)_foreground"/>
        </adaptive-icon>
        """

        try adaptiveXML.write(
            to: anydpiURL.appendingPathComponent("\(baseFileName).xml"),
            atomically: true,
            encoding: .utf8
        )
        try adaptiveXML.write(
            to: anydpiURL.appendingPathComponent("\(baseFileName)_round.xml"),
            atomically: true,
            encoding: .utf8
        )

        let valuesURL = outputRoot.appendingPathComponent("values", isDirectory: true)
        try fileManager.createDirectory(at: valuesURL, withIntermediateDirectories: true)

        let colorsXML = """
        <?xml version="1.0" encoding="utf-8"?>
        <resources>
            <color name="\(baseFileName)_background">\(IconSpecs.androidAdaptiveBackgroundColorHex)</color>
        </resources>
        """

        try colorsXML.write(
            to: valuesURL.appendingPathComponent("\(baseFileName)_background.xml"),
            atomically: true,
            encoding: .utf8
        )

        logs.append(GenerationLogEntry(
            kind: .androidAdaptiveIcon,
            message: AppLanguage.localized("Android 어댑티브 아이콘 생성 완료"),
            path: anydpiURL.path
        ))
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

    private func resizedOpaqueImage(
        from source: CGImage,
        to size: Int,
        background: CGColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
    ) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return nil
        }

        context.setFillColor(background)
        context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        context.interpolationQuality = .high
        context.draw(source, in: CGRect(x: 0, y: 0, width: size, height: size))

        return context.makeImage()
    }

    /// iOS 18 Tinted 아이콘용: 시스템이 색을 입힐 수 있도록 흑백(grayscale) 단일 채널로 생성한다.
    private func resizedGrayscaleOpaqueImage(from source: CGImage, to size: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ), let white = CGColor(colorSpace: colorSpace, components: [1.0, 1.0]) else {
            return nil
        }

        context.setFillColor(white)
        context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        context.interpolationQuality = .high
        context.draw(source, in: CGRect(x: 0, y: 0, width: size, height: size))

        return context.makeImage()
    }

    private func resizedForegroundImage(from source: CGImage, canvasSize: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: canvasSize,
            height: canvasSize,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .high

        let contentSize = Double(canvasSize) * IconSpecs.androidAdaptiveSafeZoneRatio
        let origin = (Double(canvasSize) - contentSize) / 2
        context.draw(source, in: CGRect(x: origin, y: origin, width: contentSize, height: contentSize))

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
