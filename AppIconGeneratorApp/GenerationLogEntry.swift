import Foundation

/// 생성 결과 한 줄을 나타낸다. `kind`는 결과 화면(ResultSheetView)에서 아이콘/색상을
/// 고르는 데 쓰이는 언어 독립적인 값이고, `message`는 사용자에게 보여줄 로컬라이즈된 문장이다.
/// (예전에는 `message` 문자열 안의 한국어 키워드를 매칭해서 아이콘을 골랐는데, 다국어를
/// 지원하면 언어가 바뀔 때마다 매칭이 깨지므로 이렇게 분리했다.)
enum GenerationLogKind {
    case appleIconSet(ApplePlatform)
    case androidIconSet
    case androidAdaptiveIcon
    case iosUniversalIcon
    case appleStoreAssets
    case androidStoreAssets
    case notice
    case warning
}

struct GenerationLogEntry {
    let kind: GenerationLogKind
    let message: String
    let path: String?
}
