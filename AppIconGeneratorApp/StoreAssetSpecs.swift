import Foundation

struct StoreAssetSpec {
    let fileName: String
    let width: Int
    let height: Int
}

enum StoreAssetSpecs {
    /// App Store Connect는 플랫폼별로 아래 사이즈 중 하나만 업로드하면 나머지는 자동 스케일링됩니다.
    /// 실제 캡처 해상도에 맞는 파일을 골라 스크린샷으로 교체해서 사용하세요.
    static let appleMac: [StoreAssetSpec] = [
        .init(fileName: "appstore-mac-1280x800.png", width: 1280, height: 800),
        .init(fileName: "appstore-mac-1440x900.png", width: 1440, height: 900),
        .init(fileName: "appstore-mac-2560x1600.png", width: 2560, height: 1600),
        .init(fileName: "appstore-mac-2880x1800.png", width: 2880, height: 1800)
    ]

    static let appleIPhone: [StoreAssetSpec] = [
        .init(fileName: "appstore-iphone-6.9in-1320x2868.png", width: 1320, height: 2868)
    ]

    static let appleIPad: [StoreAssetSpec] = [
        .init(fileName: "appstore-ipad-13in-2064x2752.png", width: 2064, height: 2752)
    ]

    static let androidPlayStore: [StoreAssetSpec] = [
        .init(fileName: "playstore-feature-graphic-1024x500.png", width: 1024, height: 500),
        .init(fileName: "playstore-phone-screenshot-1080x1920.png", width: 1080, height: 1920)
    ]
}
