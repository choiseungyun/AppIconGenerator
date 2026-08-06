import Foundation

/// 사용자가 앱 안에서 직접 고른 언어. SwiftUI View 트리는 `.environment(\.locale:)`로
/// 반영되지만, IconGenerator/StoreAssetGenerator/GeminiIconService처럼 View가 아닌
/// 코드에서 만드는 문자열(결과 로그, 에러 메시지)은 그 환경 값을 볼 수 없다.
/// 그래서 그런 곳에서는 `AppLanguage.localized(...)`로 명시적으로 현재 선택된
/// 언어를 넘겨서 로컬라이즈해야, 토글 버튼을 눌렀을 때 모든 화면이 함께 바뀐다.
enum AppLanguage: String, CaseIterable, Identifiable {
    case korean = "ko"
    case english = "en"

    var id: String { rawValue }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var displayName: String {
        switch self {
        case .korean: return "한국어"
        case .english: return "English"
        }
    }

    /// 토글 버튼에 보여줄, "누르면 바뀔 언어"의 짧은 라벨.
    var switchToLabel: String {
        switch self {
        case .korean: return "EN"
        case .english: return "한글"
        }
    }

    static let storageKey = "AppIconGenerator.selectedLanguage"

    static var systemDefault: AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("ko") ? .korean : .english
    }

    static var current: AppLanguage {
        if let raw = UserDefaults.standard.string(forKey: storageKey), let language = AppLanguage(rawValue: raw) {
            return language
        }
        return systemDefault
    }

    /// `String(localized:)` 대신 쓰는 헬퍼. 현재 선택된 언어를 명시적으로 넘겨서
    /// 시스템 로케일이 아니라 앱 내부 토글 상태를 따르게 한다.
    static func localized(_ value: String.LocalizationValue) -> String {
        String(localized: value, locale: current.locale)
    }

    /// 리터럴이 아니라 런타임 문자열을 키로 쓰는 경우(예: NSOpenPanel에 전달된 제목)를 위한 버전.
    static func localized(forKey key: String) -> String {
        guard
            let path = Bundle.main.path(forResource: current.rawValue, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return key
        }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}
