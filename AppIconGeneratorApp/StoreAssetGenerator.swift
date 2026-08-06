import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// App Store Connect / Play Console 등록 시 필요한 스크린샷 사이즈의 placeholder를 생성한다.
/// 실제 스크린샷은 아니지만, 흰 배경 위에 원본 아이콘 이미지를 중앙에 배치해서
/// 정확한 픽셀 크기 + 실제 로고가 어떻게 보이는지 감을 잡을 수 있게 한다.
struct StoreAssetGenerator {
    func generate(
        sourceURL: URL,
        outputDirectory: URL,
        includeAppleStoreAssets: Bool,
        includeAndroidStoreAssets: Bool
    ) throws -> [GenerationLogEntry] {
        var logs: [GenerationLogEntry] = []

        guard includeAppleStoreAssets || includeAndroidStoreAssets else {
            return logs
        }

        guard let source = loadCGImage(from: sourceURL) else {
            throw IconGeneratorError.sourceImageLoadFailed
        }

        if includeAppleStoreAssets {
            let root = outputDirectory.appendingPathComponent("StoreAssets/Apple", isDirectory: true)
            try generateCanvases(source: source, specs: StoreAssetSpecs.appleMac, outputRoot: root)
            try generateCanvases(source: source, specs: StoreAssetSpecs.appleIPhone, outputRoot: root)
            try generateCanvases(source: source, specs: StoreAssetSpecs.appleIPad, outputRoot: root)
            logs.append(GenerationLogEntry(
                kind: .appleStoreAssets,
                message: AppLanguage.localized("Apple 스토어 등록 이미지 생성 완료 (macOS 4종 중 실제 캡처 해상도에 맞는 1개 사용 / iPhone 6.9in / iPad 13in)"),
                path: root.path
            ))
        }

        if includeAndroidStoreAssets {
            let root = outputDirectory.appendingPathComponent("StoreAssets/Android", isDirectory: true)
            try generateCanvases(source: source, specs: StoreAssetSpecs.androidPlayStore, outputRoot: root)
            logs.append(GenerationLogEntry(
                kind: .androidStoreAssets,
                message: AppLanguage.localized("Android Play Store 등록 이미지 생성 완료 (feature graphic + phone screenshot)"),
                path: root.path
            ))
        }

        return logs
    }

    private func generateCanvases(source: CGImage, specs: [StoreAssetSpec], outputRoot: URL) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: outputRoot, withIntermediateDirectories: true)

        for spec in specs {
            guard let image = canvasWithCenteredSource(source, width: spec.width, height: spec.height) else {
                throw IconGeneratorError.canvasCreationFailed(width: spec.width, height: spec.height)
            }

            let fileURL = outputRoot.appendingPathComponent(spec.fileName)
            try writePNG(image, to: fileURL)
        }
    }

    /// 흰 배경 캔버스 중앙에 원본 이미지를 정사각형 비율 그대로, 짧은 변의 60%
    /// 크기로 축소해서 배치한다. (여백을 둬서 스토어 심사 시 잘려 보이지 않도록)
    private func canvasWithCenteredSource(_ source: CGImage, width: Int, height: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return nil
        }

        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.interpolationQuality = .high

        let contentSize = Double(min(width, height)) * 0.6
        let originX = (Double(width) - contentSize) / 2
        let originY = (Double(height) - contentSize) / 2
        context.draw(source, in: CGRect(x: originX, y: originY, width: contentSize, height: contentSize))

        return context.makeImage()
    }

    private func loadCGImage(from url: URL) -> CGImage? {
        guard let nsImage = NSImage(contentsOf: url) else {
            return nil
        }

        var rect = CGRect(origin: .zero, size: nsImage.size)
        return nsImage.cgImage(forProposedRect: &rect, context: nil, hints: nil)
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
