import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

// 실제 앱 UI 없이 IconGenerator/IconSpecs 파이프라인을 직접 호출해 검증하는 통합 테스트.
// scripts/run-integration-tests.sh 로 IconSpecs.swift + IconGenerator.swift 와 함께 컴파일/실행됨.

var testCount = 0
var failureCount = 0

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    testCount += 1
    if condition() {
        print("✅ \(message)")
    } else {
        failureCount += 1
        print("❌ FAIL: \(message)")
    }
}

func fail(_ message: String) {
    testCount += 1
    failureCount += 1
    print("❌ FAIL: \(message)")
}

func makeSourceImage(size: Int, color: CGColor = CGColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1)) -> URL {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fatalError("테스트 원본 이미지용 CGContext 생성 실패")
    }

    context.clear(CGRect(x: 0, y: 0, width: size, height: size))
    context.setFillColor(color)
    context.fillEllipse(in: CGRect(x: size / 8, y: size / 8, width: size * 3 / 4, height: size * 3 / 4))

    guard let image = context.makeImage() else {
        fatalError("테스트 원본 이미지 생성 실패")
    }

    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("appicon-integration-src-\(UUID().uuidString)", isDirectory: true)
    try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let url = dir.appendingPathComponent("source.png")

    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        fatalError("테스트 원본 이미지 destination 생성 실패")
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        fatalError("테스트 원본 이미지 쓰기 실패")
    }

    return url
}

func loadCGImage(at url: URL) -> CGImage? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}

func imageHasAlpha(at url: URL) -> Bool {
    guard let image = loadCGImage(at: url) else { return false }
    switch image.alphaInfo {
    case .none, .noneSkipFirst, .noneSkipLast:
        return false
    default:
        return true
    }
}

func pixelSize(at url: URL) -> (width: Int, height: Int)? {
    guard let image = loadCGImage(at: url) else { return nil }
    return (image.width, image.height)
}

func readContentsJSON(at url: URL) -> [String: Any]? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
}

/// 지정한 픽셀 좌표 주변 2x2 영역을 1x1로 축소해서 대략적인 색을 읽는다.
func pixelIsNearWhite(at url: URL, x: Int, y: Int) -> Bool? {
    guard let image = loadCGImage(at: url) else { return nil }
    let clampedX = max(0, min(x, image.width - 2))
    let clampedY = max(0, min(y, image.height - 2))
    guard let cropped = image.cropping(to: CGRect(x: clampedX, y: clampedY, width: 2, height: 2)) else { return nil }

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
        space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else { return nil }

    context.interpolationQuality = .none
    context.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))

    guard let data = context.data else { return nil }
    let ptr = data.bindMemory(to: UInt8.self, capacity: 4)
    return ptr[0] > 250 && ptr[1] > 250 && ptr[2] > 250
}

let fm = FileManager.default
let workDir = fm.temporaryDirectory.appendingPathComponent("appicon-integration-out-\(UUID().uuidString)", isDirectory: true)
try! fm.createDirectory(at: workDir, withIntermediateDirectories: true)
print("작업 디렉터리: \(workDir.path)\n")

let generator = IconGenerator()
let sourceURL = makeSourceImage(size: 1024)

// MARK: - Test 1: 전체 플랫폼 생성 (Apple 4종 + iOS Universal + Android)

print("--- Test 1: 전체 플랫폼 생성 ---")
let allOutputDir = workDir.appendingPathComponent("all", isDirectory: true)
do {
    let logs = try generator.generate(
        sourceURL: sourceURL,
        outputDirectory: allOutputDir,
        includeIPhone: true,
        includeIPad: true,
        includeMacOS: true,
        includeWatchOS: true,
        includeIOSUniversal: true,
        iOSUniversalDarkURL: nil,
        iOSUniversalTintedURL: nil,
        includeAndroid: true,
        androidBaseFileName: "ic_launcher",
        androidTargetRoot: "mipmap"
    )
    check(!logs.isEmpty, "전체 생성 로그 반환됨")

    // 로그의 kind가 언어와 무관하게 정확한 플랫폼을 가리키는지 확인 (메시지 텍스트가 아니라 구조로 판별)
    let applePlatformKinds: [ApplePlatform] = logs.compactMap {
        if case let .appleIconSet(platform) = $0.kind { return platform }
        return nil
    }
    check(Set(applePlatformKinds) == Set([.iPhone, .iPad, .macOS, .watchOS]), "appleIconSet kind가 iPhone/iPad/macOS/watchOS 4종 모두 포함 (실제: \(applePlatformKinds))")
    check(logs.contains { if case .androidIconSet = $0.kind { return true }; return false }, "androidIconSet kind 포함")
    check(logs.contains { if case .androidAdaptiveIcon = $0.kind { return true }; return false }, "androidAdaptiveIcon kind 포함")
    check(logs.contains { if case .iosUniversalIcon = $0.kind { return true }; return false }, "iosUniversalIcon kind 포함")
    check(logs.contains { if case .notice = $0.kind { return true }; return false }, "notice kind(Include All App Icon Assets 안내) 포함")
    check(logs.allSatisfy { entry in
        if case .notice = entry.kind { return entry.path == nil }
        return true
    }, "notice kind 항목은 path가 nil")
} catch {
    fail("전체 생성 실패: \(error)")
}

// iPhone
let iPhoneSet = allOutputDir.appendingPathComponent("iPhone/AppIcon.appiconset")
let iPhonePNGs = ((try? fm.contentsOfDirectory(atPath: iPhoneSet.path)) ?? []).filter { $0.hasSuffix(".png") }
check(iPhonePNGs.count == 9, "iPhone PNG 9개 생성 (실제 \(iPhonePNGs.count)개)")

let iPhoneMarketing = iPhoneSet.appendingPathComponent("ios-marketing-1024.0x1024.0@1x.png")
check(fm.fileExists(atPath: iPhoneMarketing.path), "iPhone ios-marketing 1024 아이콘 파일 존재")
check(!imageHasAlpha(at: iPhoneMarketing), "iPhone ios-marketing 아이콘 알파 채널 없음 (App Store 요구사항)")
check(pixelSize(at: iPhoneMarketing).map { $0.width == 1024 && $0.height == 1024 } ?? false, "iPhone ios-marketing 아이콘 1024x1024 픽셀")

if let json = readContentsJSON(at: iPhoneSet.appendingPathComponent("Contents.json")),
   let images = json["images"] as? [[String: Any]] {
    check(images.count == 9, "iPhone Contents.json images 9개 (실제 \(images.count)개)")
    check(images.contains { ($0["idiom"] as? String) == "ios-marketing" }, "iPhone Contents.json에 ios-marketing idiom 포함")
} else {
    fail("iPhone Contents.json 파싱 실패")
}

// iPad
let iPadSet = allOutputDir.appendingPathComponent("iPad/AppIcon.appiconset")
let iPadPNGs = ((try? fm.contentsOfDirectory(atPath: iPadSet.path)) ?? []).filter { $0.hasSuffix(".png") }
check(iPadPNGs.count == 10, "iPad PNG 10개 생성 (실제 \(iPadPNGs.count)개)")
check(fm.fileExists(atPath: iPadSet.appendingPathComponent("ios-marketing-1024.0x1024.0@1x.png").path), "iPad ios-marketing 1024 아이콘 파일 존재")

// macOS
let macSet = allOutputDir.appendingPathComponent("macOS/AppIcon.appiconset")
let macPNGs = ((try? fm.contentsOfDirectory(atPath: macSet.path)) ?? []).filter { $0.hasSuffix(".png") }
check(macPNGs.count == 10, "macOS PNG 10개 생성 (실제 \(macPNGs.count)개)")

// watchOS
let watchSet = allOutputDir.appendingPathComponent("watchOS/AppIcon.appiconset")
let watchPNGs = ((try? fm.contentsOfDirectory(atPath: watchSet.path)) ?? []).filter { $0.hasSuffix(".png") }
check(watchPNGs.count == 8, "watchOS PNG 8개 생성 (실제 \(watchPNGs.count)개)")

// iOS Universal (Single Size)
let universalSet = allOutputDir.appendingPathComponent("iOS/AppIcon.appiconset")
let universalPNGs = ((try? fm.contentsOfDirectory(atPath: universalSet.path)) ?? []).filter { $0.hasSuffix(".png") }
check(universalPNGs == ["AppIcon-1024.png"], "iOS Universal PNG 1개(AppIcon-1024.png)만 생성")

let universalIconURL = universalSet.appendingPathComponent("AppIcon-1024.png")
check(!imageHasAlpha(at: universalIconURL), "iOS Universal 아이콘 알파 채널 없음")
check(pixelSize(at: universalIconURL).map { $0.width == 1024 && $0.height == 1024 } ?? false, "iOS Universal 아이콘 1024x1024 픽셀")

if let json = readContentsJSON(at: universalSet.appendingPathComponent("Contents.json")),
   let images = json["images"] as? [[String: Any]], let first = images.first {
    check(images.count == 1, "iOS Universal Contents.json images 1개")
    check((first["idiom"] as? String) == "universal", "iOS Universal idiom = universal")
    check((first["platform"] as? String) == "ios", "iOS Universal platform = ios")
    check((first["size"] as? String) == "1024x1024", "iOS Universal size = 1024x1024")
    check(first["appearances"] == nil, "iOS Universal 기본 아이콘엔 appearances 없음 (Dark/Tinted 미지정)")
} else {
    fail("iOS Universal Contents.json 파싱 실패")
}

// MARK: - Test 1b: iOS Universal + Dark/Tinted 아이콘

print("\n--- Test 1b: iOS Universal Dark/Tinted ---")
let darkSourceURL = makeSourceImage(size: 1024, color: CGColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1))
let tintedSourceURL = makeSourceImage(size: 1024, color: CGColor(red: 0.1, green: 0.7, blue: 0.2, alpha: 1))
let darkTintedOutputDir = workDir.appendingPathComponent("dark-tinted", isDirectory: true)
do {
    let logs = try generator.generate(
        sourceURL: sourceURL,
        outputDirectory: darkTintedOutputDir,
        includeIPhone: false,
        includeIPad: false,
        includeMacOS: false,
        includeWatchOS: false,
        includeIOSUniversal: true,
        iOSUniversalDarkURL: darkSourceURL,
        iOSUniversalTintedURL: tintedSourceURL,
        includeAndroid: false,
        androidBaseFileName: "ic_launcher",
        androidTargetRoot: "mipmap"
    )

    let universalEntry = logs.first { if case .iosUniversalIcon = $0.kind { return true }; return false }
    check(universalEntry?.message.contains("Dark") == true && universalEntry?.message.contains("Tinted") == true, "iosUniversalIcon 메시지에 Dark/Tinted 포함 표기됨")

    let dtSet = darkTintedOutputDir.appendingPathComponent("iOS/AppIcon.appiconset")
    let dtPNGs = ((try? fm.contentsOfDirectory(atPath: dtSet.path)) ?? []).filter { $0.hasSuffix(".png") }
    check(Set(dtPNGs) == Set(["AppIcon-1024.png", "AppIcon-1024-dark.png", "AppIcon-1024-tinted.png"]), "Dark/Tinted 지정 시 PNG 3개 생성 (실제: \(dtPNGs.sorted()))")

    if let json = readContentsJSON(at: dtSet.appendingPathComponent("Contents.json")),
       let images = json["images"] as? [[String: Any]] {
        check(images.count == 3, "Dark/Tinted Contents.json images 3개 (실제 \(images.count)개)")

        let darkEntry = images.first { ($0["filename"] as? String) == "AppIcon-1024-dark.png" }
        let darkAppearances = darkEntry?["appearances"] as? [[String: String]]
        check(darkAppearances?.first?["appearance"] == "luminosity" && darkAppearances?.first?["value"] == "dark", "dark 항목 appearances = luminosity/dark")

        let tintedEntry = images.first { ($0["filename"] as? String) == "AppIcon-1024-tinted.png" }
        let tintedAppearances = tintedEntry?["appearances"] as? [[String: String]]
        check(tintedAppearances?.first?["appearance"] == "luminosity" && tintedAppearances?.first?["value"] == "tinted", "tinted 항목 appearances = luminosity/tinted")
    } else {
        fail("Dark/Tinted Contents.json 파싱 실패")
    }

    let darkIconURL = dtSet.appendingPathComponent("AppIcon-1024-dark.png")
    check(!imageHasAlpha(at: darkIconURL), "dark 아이콘 알파 채널 없음")
    check(pixelIsNearWhite(at: darkIconURL, x: 2, y: 2) == false, "dark 아이콘 모서리가 검정 배경으로 flatten됨 (흰색 아님)")

    let tintedIconURL = dtSet.appendingPathComponent("AppIcon-1024-tinted.png")
    if let tintedImage = loadCGImage(at: tintedIconURL) {
        check(tintedImage.colorSpace?.model == .monochrome, "tinted 아이콘이 흑백(grayscale) 컬러스페이스로 저장됨")
    } else {
        fail("tinted 아이콘 로드 실패")
    }
} catch {
    fail("iOS Universal Dark/Tinted 생성 실패: \(error)")
}

// Android
let androidRoot = allOutputDir.appendingPathComponent("Android")
for density in ["mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"] {
    let folder = androidRoot.appendingPathComponent("mipmap-\(density)")
    check(fm.fileExists(atPath: folder.appendingPathComponent("ic_launcher.png").path), "Android mipmap-\(density)/ic_launcher.png 존재")
    check(fm.fileExists(atPath: folder.appendingPathComponent("ic_launcher_round.png").path), "Android mipmap-\(density)/ic_launcher_round.png 존재")
    check(fm.fileExists(atPath: folder.appendingPathComponent("ic_launcher_foreground.png").path), "Android mipmap-\(density)/ic_launcher_foreground.png 존재 (adaptive)")
}

let mdpiForeground = androidRoot.appendingPathComponent("mipmap-mdpi/ic_launcher_foreground.png")
check(pixelSize(at: mdpiForeground).map { $0.width == 108 && $0.height == 108 } ?? false, "Android mdpi foreground 캔버스 108x108")

let anydpiFolder = androidRoot.appendingPathComponent("mipmap-anydpi-v26")
check(fm.fileExists(atPath: anydpiFolder.appendingPathComponent("ic_launcher.xml").path), "Android mipmap-anydpi-v26/ic_launcher.xml 존재")
check(fm.fileExists(atPath: anydpiFolder.appendingPathComponent("ic_launcher_round.xml").path), "Android mipmap-anydpi-v26/ic_launcher_round.xml 존재")

let adaptiveXML = (try? String(contentsOf: anydpiFolder.appendingPathComponent("ic_launcher.xml"), encoding: .utf8)) ?? ""
check(adaptiveXML.contains("@mipmap/ic_launcher_foreground"), "adaptive icon XML이 foreground 드로어블 참조")
check(adaptiveXML.contains("@color/ic_launcher_background"), "adaptive icon XML이 background 컬러 참조")

let backgroundColorXML = androidRoot.appendingPathComponent("values/ic_launcher_background.xml")
check(fm.fileExists(atPath: backgroundColorXML.path), "Android values/ic_launcher_background.xml 존재")

let playStoreIcon = androidRoot.appendingPathComponent("playstore/ic_launcher-playstore.png")
check(fm.fileExists(atPath: playStoreIcon.path), "Android playstore 아이콘 존재")
check(pixelSize(at: playStoreIcon).map { $0.width == 512 && $0.height == 512 } ?? false, "Android playstore 아이콘 512x512 픽셀")

// MARK: - Test 2: Android target folder를 drawable로 지정

print("\n--- Test 2: Android target folder = drawable ---")
let drawableOutputDir = workDir.appendingPathComponent("drawable", isDirectory: true)
do {
    _ = try generator.generate(
        sourceURL: sourceURL,
        outputDirectory: drawableOutputDir,
        includeIPhone: false,
        includeIPad: false,
        includeMacOS: false,
        includeWatchOS: false,
        includeIOSUniversal: false,
        iOSUniversalDarkURL: nil,
        iOSUniversalTintedURL: nil,
        includeAndroid: true,
        androidBaseFileName: "app_icon",
        androidTargetRoot: "drawable"
    )
    let drawableMdpi = drawableOutputDir.appendingPathComponent("Android/drawable-mdpi/app_icon.png")
    check(fm.fileExists(atPath: drawableMdpi.path), "drawable-mdpi/app_icon.png 생성 (커스텀 파일명/타겟폴더 반영)")
    check(!fm.fileExists(atPath: drawableOutputDir.appendingPathComponent("Android/mipmap-mdpi").path), "mipmap 폴더는 생성되지 않음")
} catch {
    fail("drawable 타겟 생성 실패: \(error)")
}

// MARK: - Test 2b: 스토어 등록 이미지(빈 캔버스) 생성

print("\n--- Test 2b: 스토어 등록 이미지 생성 (원본 이미지 중앙 배치) ---")
let storeAssetsOutputDir = workDir.appendingPathComponent("store-assets", isDirectory: true)
let storeAssetGenerator = StoreAssetGenerator()
do {
    let logs = try storeAssetGenerator.generate(
        sourceURL: sourceURL,
        outputDirectory: storeAssetsOutputDir,
        includeAppleStoreAssets: true,
        includeAndroidStoreAssets: true
    )
    check(logs.count == 2, "스토어 등록 이미지 로그 2줄(Apple/Android) 반환")
    check(logs.contains { if case .appleStoreAssets = $0.kind { return true }; return false }, "appleStoreAssets kind 포함")
    check(logs.contains { if case .androidStoreAssets = $0.kind { return true }; return false }, "androidStoreAssets kind 포함")

    let appleRoot = storeAssetsOutputDir.appendingPathComponent("StoreAssets/Apple")
    for spec in StoreAssetSpecs.appleMac + StoreAssetSpecs.appleIPhone + StoreAssetSpecs.appleIPad {
        let fileURL = appleRoot.appendingPathComponent(spec.fileName)
        check(fm.fileExists(atPath: fileURL.path), "Apple 스토어 이미지 존재: \(spec.fileName)")
        check(pixelSize(at: fileURL).map { $0.width == spec.width && $0.height == spec.height } ?? false, "\(spec.fileName) 크기 \(spec.width)x\(spec.height)")
        check(!imageHasAlpha(at: fileURL), "\(spec.fileName) 알파 채널 없음")
        check(pixelIsNearWhite(at: fileURL, x: spec.width / 2, y: spec.height / 2) == false, "\(spec.fileName) 중앙에 원본 이미지 내용 배치됨 (흰색 아님)")
        check(pixelIsNearWhite(at: fileURL, x: 2, y: 2) == true, "\(spec.fileName) 모서리는 흰 배경 유지")
    }

    let androidRoot = storeAssetsOutputDir.appendingPathComponent("StoreAssets/Android")
    for spec in StoreAssetSpecs.androidPlayStore {
        let fileURL = androidRoot.appendingPathComponent(spec.fileName)
        check(fm.fileExists(atPath: fileURL.path), "Android 스토어 이미지 존재: \(spec.fileName)")
        check(pixelSize(at: fileURL).map { $0.width == spec.width && $0.height == spec.height } ?? false, "\(spec.fileName) 크기 \(spec.width)x\(spec.height)")
        check(pixelIsNearWhite(at: fileURL, x: spec.width / 2, y: spec.height / 2) == false, "\(spec.fileName) 중앙에 원본 이미지 내용 배치됨 (흰색 아님)")
        check(pixelIsNearWhite(at: fileURL, x: 2, y: 2) == true, "\(spec.fileName) 모서리는 흰 배경 유지")
    }
} catch {
    fail("스토어 등록 이미지 생성 실패: \(error)")
}

do {
    let logs = try storeAssetGenerator.generate(
        sourceURL: sourceURL,
        outputDirectory: storeAssetsOutputDir.appendingPathComponent("none"),
        includeAppleStoreAssets: false,
        includeAndroidStoreAssets: false
    )
    check(logs.isEmpty, "옵션 미선택 시 스토어 등록 이미지 로그 없음")
    check(!fm.fileExists(atPath: storeAssetsOutputDir.appendingPathComponent("none").path), "옵션 미선택 시 출력 폴더 미생성 (불필요한 원본 이미지 로드도 생략)")
} catch {
    fail("스토어 등록 이미지 미선택 케이스에서 예외 발생: \(error)")
}

// MARK: - Test 3: 플랫폼 미선택

print("\n--- Test 3: 플랫폼 미선택 ---")
let emptyOutputDir = workDir.appendingPathComponent("empty", isDirectory: true)
do {
    let logs = try generator.generate(
        sourceURL: sourceURL,
        outputDirectory: emptyOutputDir,
        includeIPhone: false,
        includeIPad: false,
        includeMacOS: false,
        includeWatchOS: false,
        includeIOSUniversal: false,
        iOSUniversalDarkURL: nil,
        iOSUniversalTintedURL: nil,
        includeAndroid: false,
        androidBaseFileName: "ic_launcher",
        androidTargetRoot: "mipmap"
    )
    check(logs.count == 1, "플랫폼 미선택 시 로그 1줄만 반환 (실제 \(logs.count)줄)")
    if case .warning = logs.first?.kind {
        check(logs.first?.message == "선택된 플랫폼이 없어 파일을 생성하지 않았습니다.", "플랫폼 미선택 경고 메시지 정확함")
    } else {
        fail("플랫폼 미선택 로그의 kind가 .warning이 아님")
    }
    check(!fm.fileExists(atPath: emptyOutputDir.path), "플랫폼 미선택 시 출력 폴더 미생성")
} catch {
    fail("플랫폼 미선택 케이스에서 예외 발생: \(error)")
}

// MARK: - Test 4: 원본 이미지가 너무 작은 경우 에러

print("\n--- Test 4: 원본 이미지 최소 크기 미달 ---")
let smallSourceURL = makeSourceImage(size: 512)
let smallOutputDir = workDir.appendingPathComponent("small", isDirectory: true)
do {
    _ = try generator.generate(
        sourceURL: smallSourceURL,
        outputDirectory: smallOutputDir,
        includeIPhone: true,
        includeIPad: false,
        includeMacOS: false,
        includeWatchOS: false,
        includeIOSUniversal: false,
        iOSUniversalDarkURL: nil,
        iOSUniversalTintedURL: nil,
        includeAndroid: false,
        androidBaseFileName: "ic_launcher",
        androidTargetRoot: "mipmap"
    )
    fail("512x512 원본에서 에러가 발생해야 하는데 성공 처리됨")
} catch IconGeneratorError.sourceImageTooSmall(let required, let actual) {
    check(required == 1024 && actual == 512, "sourceImageTooSmall 에러 값 확인 (required=\(required), actual=\(actual))")
} catch {
    fail("예상치 못한 에러 타입 발생: \(error)")
}

// MARK: - Summary

print("\n총 \(testCount)개 중 \(failureCount)개 실패")
try? fm.removeItem(at: workDir)
try? fm.removeItem(at: sourceURL.deletingLastPathComponent())
try? fm.removeItem(at: smallSourceURL.deletingLastPathComponent())

if failureCount > 0 {
    exit(1)
}
print("모든 통합 테스트 통과 ✅")
exit(0)
