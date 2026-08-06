# 개선 사항

최신 앱 배포 기준(iOS/Android)으로 점검한 결과와 진행 상태를 정리합니다.

## 완료

### 1. App Store 마케팅 아이콘(1024) 누락 → 추가 완료
iPhone/iPad `AppIcon.appiconset`에 `ios-marketing`(1024x1024, scale 1x) 항목이 없어 App Store Connect 제출 검증(투명도 없는 1024 아이콘 필수)을 통과하지 못하는 문제였습니다.

- [IconSpecs.swift](AppIconGeneratorApp/IconSpecs.swift)의 iPhone/iPad 스펙에 `ios-marketing` 엔트리 추가
- [IconGenerator.swift](AppIconGeneratorApp/IconGenerator.swift)에 `resizedOpaqueImage`를 추가해 알파 채널을 제거(흰 배경 flatten)한 상태로 생성

### 2. Android 어댑티브 아이콘 미지원 → 추가 완료
Android 8.0(API 26)부터 표준인 foreground/background 레이어 기반 어댑티브 아이콘이 없고, 예전 방식의 단일 PNG만 밀도별로 생성되고 있었습니다.

- `mipmap-anydpi-v26/ic_launcher.xml` (+ `_round.xml`) 생성
- 밀도별 `ic_launcher_foreground.png` 생성 (safe zone 66% 축소 적용)
- `values/ic_launcher_background.xml` 배경 색상 리소스 생성
- 레거시 `mipmap-*/ic_launcher.png`는 하위 호환을 위해 계속 생성

### 3. Xcode 14+ "Single Size" 아이콘 워크플로 미반영 → 추가 완료
Xcode 14부터는 1024 원본 하나만 넣고 `Include All App Icon Assets` 빌드 세팅을 켜면 나머지 사이즈를 Xcode가 자동 생성합니다. 지금처럼 여러 PNG를 미리 렌더링하는 방식도 동작은 하지만 최신 권장 방식은 아니었습니다.

- Apple targets에 **"iOS Universal (Single Size, Xcode 14+)"** 토글 추가 ([AppIconGeneratorApp.swift](AppIconGeneratorApp/AppIconGeneratorApp.swift))
- 켜면 `iOS/AppIcon.appiconset`에 1024x1024(알파 제거) 이미지 한 장 + `idiom: universal` Contents.json만 생성 ([IconGenerator.swift](AppIconGeneratorApp/IconGenerator.swift)의 `generateSingleSizeAppleAssets`)
- 기존 iPhone/iPad 다중 사이즈 토글과 독립적으로 동작하며 기본값은 꺼짐(opt-in)
- Xcode 프로젝트 Build Settings에서 `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES`를 직접 켜줘야 함 (결과 로그와 README에 안내 문구 추가)

### 4. App Store Connect / Play Console 등록 필수 스크린샷 사이즈 미지원 → 추가 완료
앱 아이콘만 생성하고, 실제 스토어 등록 시 함께 올려야 하는 스크린샷/그래픽 자산의 사이즈는 다루지 않고 있었습니다. 사용자가 App Store Connect 스크린샷 업로드 화면(macOS 1280x800/1440x900/2560x1600/2880x1800)을 보고 요청.

- [StoreAssetSpecs.swift](AppIconGeneratorApp/StoreAssetSpecs.swift), [StoreAssetGenerator.swift](AppIconGeneratorApp/StoreAssetGenerator.swift) 신규 추가
- "스토어 등록 이미지" 섹션을 UI에 추가, Apple/Android 각각 독립 토글 (기본값 꺼짐)
- 실제 스크린샷이 아닌 **흰 배경 중앙에 원본 이미지를 배치한 placeholder**를 필수 최소 사이즈로 생성 (Apple: macOS 4종 중 실사용 해상도 1개 선택 / iPhone 6.9in / iPad 13in, Android: feature graphic 1024x500 + phone 스크린샷 1080x1920)
- 파일명에 용도+사이즈를 명시(`appstore-mac-1280x800.png`, `playstore-feature-graphic-1024x500.png` 등)해서 어디에 쓰는 이미지인지 파일명만으로 구분 가능
- `StoreAssets/Apple`, `StoreAssets/Android` 폴더로 출력되며 앱 아이콘 생성과 독립적으로 동작
- (업데이트) 처음엔 빈 캔버스로 구현했다가, 원본 아이콘 이미지를 짧은 변의 60% 크기로 중앙 배치하도록 변경 — 실제 로고가 어떻게 보이는지 바로 확인 가능해짐. 옵션 미선택 시엔 원본 이미지 로드 자체를 생략

### 5. iOS 18 Dark / Tinted 아이콘 미지원 → 추가 완료
iOS 18부터 사용자가 홈 화면에서 앱 아이콘을 Dark/Tinted 모드로 전환할 수 있는데, `Contents.json`에 `appearance` variant(`luminosity: dark` 등) 항목이 필요합니다. 기본(라이트) 버전만 생성되고 있었습니다.

- "iOS Universal (Single Size)" 옵션을 켰을 때만 노출되는 **Dark 아이콘 / Tinted 아이콘** 선택 UI 추가 (둘 다 선택 사항, 미지정 시 기존과 동일하게 라이트 아이콘만 생성)
- Dark 아이콘: 지정한 원본 이미지를 검정 배경으로 flatten(`AppIcon-1024-dark.png`), `Contents.json`에 `appearances: [{appearance: luminosity, value: dark}]` 항목 추가
- Tinted 아이콘: 시스템이 사용자가 고른 색으로 입히므로 자동으로 **흑백(grayscale) 컬러스페이스**로 변환해서 저장(`AppIcon-1024-tinted.png`), `appearances: [{appearance: luminosity, value: tinted}]` 추가
- [IconGenerator.swift](AppIconGeneratorApp/IconGenerator.swift)에 `resizedOpaqueImage(background:)` 파라미터화, `resizedGrayscaleOpaqueImage` 신규 추가
- iPhone/iPad 개별 사이즈 아이콘에는 적용하지 않음 — Dark/Tinted appearance는 Xcode 16 이후 universal(single-size) 슬롯 기준 기능이라 기존 "iOS Universal" 옵션에 자연스럽게 결합됨

### 6. 원본 이미지 없이 Gemini AI로 아이콘 자동 생성 → 추가 완료
사용자가 원본 이미지를 직접 준비/업로드하지 않아도, 문장 설명만으로 아이콘을 만들 수 있으면 좋겠다는 요청.

- [GeminiIconService.swift](AppIconGeneratorApp/GeminiIconService.swift) 신규 추가 — Gemini 이미지 생성 모델(`gemini-2.5-flash-image`) REST API 호출, 응답을 중앙 크롭 + 흰 배경 업스케일로 정사각형/1024px 이상으로 정규화한 뒤 임시 PNG로 저장
- [KeychainStore.swift](AppIconGeneratorApp/KeychainStore.swift) 신규 추가 — Gemini API 키를 macOS Keychain에 저장(평문 저장 없음), [APIKeySettingsView.swift](AppIconGeneratorApp/APIKeySettingsView.swift)에서 입력/삭제
- 헤더 아래 "AI로 생성" 바에 프롬프트 입력 + 생성 버튼 + API 키 설정 버튼 추가. 생성 성공 시 기존 `sourceImageURL`/`outputDirectoryURL` 흐름에 그대로 편입되어(출력 폴더 기본값은 `~/Downloads/AppIcon`) 이후 단계(플랫폼 선택, Generate files)는 파일을 직접 올렸을 때와 동일하게 동작
- 네트워크/파싱 실패, API 키 미설정 등은 인라인 에러 메시지로 표시
- 모델 이름은 Google이 교체할 수 있어 상수로 분리해둠 — 요청이 계속 실패하면 이 값부터 확인 필요
- **버그 수정 (실사용 중 발견)**: 요청 실패 시(예: 무료 티어 429 rate limit) Google이 반환하는 원본 에러 JSON 전체를 그대로 에러 메시지로 노출해서, 창이 고정 크기인데도 텍스트가 넘쳐 레이아웃이 깨지는 문제가 있었음. `{"error":{"code","message","status"}}` 표준 형태만 파싱해서 짧은 메시지만 추출하고, 429는 `retryDelay`까지 뽑아 안내하도록 수정. UI에도 `.lineLimit(3)` 방어선을 추가해 파싱이 실패해도 레이아웃이 깨지지 않도록 함
- **버그 수정 (App Store Connect 업로드 중 발견)**: 프로젝트에 entitlements 파일이 아예 없어서 "App sandbox not enabled" 오류로 업로드가 거부됨. [AppIconGenerator.entitlements](AppIconGeneratorApp/AppIconGenerator.entitlements) 신규 추가 후 Debug/Release 양쪽 타깃 빌드 설정에 `CODE_SIGN_ENTITLEMENTS`로 등록:
  - `com.apple.security.app-sandbox` — Mac App Store 필수 요건
  - `com.apple.security.network.client` — Gemini API 호출(URLSession)에 필요, 없으면 샌드박스에서 네트워크 요청이 조용히 실패함
  - `com.apple.security.files.user-selected.read-write` — NSOpenPanel로 고른 원본 이미지/출력 폴더 읽기·쓰기
  - `com.apple.security.files.downloads.read-write` — AI 생성 아이콘의 기본 출력 폴더(`~/Downloads/AppIcon`)가 패널을 거치지 않고 코드로 지정되므로, 이 entitlement 없이는 사용자가 "Choose"로 다시 선택하지 않는 한 쓰기가 실패함
- **버그 수정 (실사용 중 발견 — "StoreAssets 폴더에 Apple 파일을 저장할 수 있는 권한이 없습니다")**: App Sandbox 적용 후 "Generate files"를 눌렀을 때 하위 폴더 생성이 거부됨.
  - **1차 시도(효과 없었음)**: `NSOpenPanel` URL의 보안 스코프 접근이 패널이 닫힌 직후에만 유효하고 이후 만료됐을 거라 보고 `generateIcons()` 진입 시 `startAccessingSecurityScopedResource()`를 명시적으로 호출 — 사용자가 재현했을 때 동일한 오류가 계속 발생해 원인이 아니었음이 확인됨
  - **실제 원인**: "출력 폴더"가 사용자가 패널로 직접 고른 게 아니라, 원본 이미지 파일명 옆에 있을 것으로 **추측만 해서** 자동 채운 경로였음. App Sandbox의 `files.user-selected.read-write`는 사용자가 패널로 실제 선택한 항목에만 부여되는데, 이미지 파일 하나를 고르면 그 파일에 대한 권한만 생기지 그 옆에 새 폴더를 만들 권한은 생기지 않음. 지금까지 "Choose"를 누르지 않고 자동 제안된 경로로 바로 생성해도 됐던 게, 샌드박스에서는 애초에 항상 거부될 수밖에 없는 흐름이었음
  - **수정**: `outputDirectoryIsGranted` 플래그를 추가해 "실제 패널로 승인된 폴더"와 "추측으로만 채운 폴더"를 구분. `updateSourceImageSelection`(이미지 선택 시 자동 제안)에서는 `false`로, "Choose" 버튼으로 명시적으로 고르면 `true`로 설정. `~/Downloads/AppIcon`(AI 생성 아이콘의 기본 출력 경로)은 `com.apple.security.files.downloads.read-write` entitlement로 이미 커버되므로 예외적으로 `true`. `generateIcons()`에서 승인되지 않은 폴더면 실제 쓰기 전에 같은 위치를 미리 채워둔 `chooseOutputFolder()` 패널을 한 번 더 띄워 진짜 승인을 받고, 취소하면 조용히 중단
  - (참고: 이 환경엔 Xcode GUI가 없어 실제 재현/검증은 못 했고, 에러 문구·샌드박스 동작 원리·사용자의 재현 결과에 근거한 진단)

### 7. 다국어(한국어/영어) 지원 → 추가 완료
사용자 요청: macOS 시스템 언어가 한국어면 한국어, 그 외에는 영어로 자동 표시.

- [Localizable.xcstrings](AppIconGeneratorApp/Localizable.xcstrings) 신규 추가 (123개 수동 등록 키, `ko`/`en` 양쪽 번역 명시 + Xcode가 자동 추출한 스텝 번호 배지 1개 = 총 124개) — 모든 화면 텍스트, 인앱 가이드, 결과 메시지, 에러 메시지를 포함
- **구조적 버그를 먼저 고침**: `ResultSheetView`가 결과 로그 문자열 안의 한국어 키워드(`title.contains("어댑티브")`, `title.contains("iPhone")` 등)로 아이콘/색상을 골랐는데, 이 방식은 문자열이 번역되는 순간 전부 깨지는 구조였음. [GenerationLogEntry.swift](AppIconGeneratorApp/GenerationLogEntry.swift)를 신규 추가해 언어와 무관한 `kind` enum(`.appleIconSet(ApplePlatform)`, `.androidAdaptiveIcon`, `.notice` 등)을 도입하고, `IconGenerator`/`StoreAssetGenerator`가 `[String]` 대신 `[GenerationLogEntry]`(kind + 로컬라이즈된 message + path)를 반환하도록 리팩터링. `ResultSheetView`의 아이콘 선택은 이제 `kind`만으로 판단
- 동적 메시지(경로, 크기, 에러 상세 등이 들어가는 문장)는 `String(localized: "...")`가 만드는 암묵적 interpolation 키에 기대지 않고, `String(format:)` + 명시적 `%@`/`%ld` 포맷 문자열을 사용 — Xcode의 실제 문자열 추출기로 검증할 수 없는 환경이라, 키 텍스트를 스스로 완전히 통제하기 위함. `%ld`를 쓴 이유: 64비트 Swift `Int`에 `%d`(32비트)를 쓰면 값이 깨질 수 있음
- `Text(someString)`처럼 **변수**를 표시하는 곳은 SwiftUI가 리터럴에만 적용하는 자동 로컬라이즈 매칭이 적용되지 않는다는 점을 발견 — `guideCard`의 title/step/note, `wrappingToggle`/`wrappingHint`/`auxIconRow` 등 재사용 헬퍼에 전달되는 문자열이 전부 여기 해당해서, `Text(LocalizedStringKey(value))`로 명시적으로 감쌈. `NSOpenPanel.title`(AppKit)도 SwiftUI의 자동 로컬라이즈 대상이 아니라 `String(localized:)`/`NSLocalizedString`으로 별도 처리
- 파이썬 스크립트로 소스 코드의 모든 리터럴 문자열과 카탈로그 키를 상호 대조해서, 누락되거나 고아가 된 키가 없는지 검증 (한글이 포함된 리터럴 100% 커버리지 확인)
- `project.pbxproj`의 `knownRegions`에 `ko` 추가, `Localizable.xcstrings`를 Resources 빌드 페이즈에 등록
- 통합 테스트에 `kind` 필드 기반 검증 추가 (메시지 텍스트가 아니라 구조로 플랫폼을 식별하는지 확인) — 총 105개 통과
- **(후속 요청) 수동 언어 전환 버튼 추가**: 기본은 시스템 로케일을 따르되, 헤더에 "EN"/"한글" 버튼을 둬서 언제든 즉시 전환하고 그 선택을 `UserDefaults`에 저장하도록 요청받음
  - [AppLanguage.swift](AppIconGeneratorApp/AppLanguage.swift) 신규 추가 — 선택된 언어 상태 관리(`current`), View용 `.locale` 값, View가 아닌 코드용 `localized(_:)`/`localized(forKey:)` 헬퍼 제공
  - `AppIconGeneratorApp`(App)과 `ContentView`가 같은 키로 `@AppStorage(AppLanguage.storageKey)`를 공유해서, 버튼을 누르면 `WindowGroup`의 `.environment(\.locale:)`가 즉시 갱신되고 앱 재시작 없이 모든 SwiftUI 텍스트가 바뀜
  - **View 밖 코드는 SwiftUI environment를 볼 수 없다는 점이 문제**였음 — `IconGenerator`/`StoreAssetGenerator`/`GeminiIconService`의 `String(localized: "...")` 호출은 environment locale이 아니라 시스템 로케일을 기본으로 쓰기 때문에, 버튼을 눌러도 결과 로그·에러 메시지는 안 바뀌는 반쪽짜리 기능이 될 뻔함. 그래서 이 호출들을 전부 `AppLanguage.localized(...)`로 교체(sed로 일괄 치환 후 검증)해서 현재 선택된 언어를 명시적으로 전달하도록 수정
  - `NSOpenPanel.title`도 마찬가지 이유로 `AppLanguage.localized(forKey:)`로 교체(런타임 문자열 키이므로 `Bundle(path:)`로 해당 언어의 `.lproj`를 직접 찾아 조회)
- **버그 수정 (실사용 중 발견 — "한글로 안 보여요")**: 언어 토글 버튼은 정상적으로 상태를 바꾸는데(라벨은 맞게 바뀜), 화면 텍스트는 계속 영어로만 나오는 문제가 있었음. 원인은 `Localizable.xcstrings`에 `en` 번역만 명시적으로 채우고 `ko`는 "키 자체가 이미 한국어 원문이라 번역이 필요 없다"고 생략한 것 — 이러면 Xcode가 `ko.lproj`를 아예 컴파일하지 않아서 `ko`가 번들의 "실제 지원 언어"로 등록되지 않고, `ko`를 요청해도 유일하게 콘텐츠가 있는 `en`으로 계속 폴백함. 123개 키 전부에 `ko` 번역(키와 동일한 값)도 명시적으로 채워서 해결. 소스 코드와 키 100% 일치 여부 재검증 완료
- **버그 수정 (실사용 중 발견 — 가이드/API 키 시트가 언어 전환에 반응 안 함)**: 메인 창은 언어가 바뀌는데 `.sheet`로 띄우는 iOS/Android 가이드, 결과 시트, API 키 설정 창은 계속 이전 언어로 고정되어 나옴. `.environment(\.locale:)`를 `AppIconGeneratorApp`(App, `ContentView()`를 감싸는 바깥쪽)에서 설정했더니 `ContentView` 내부의 `.sheet` 콘텐츠까지 확실히 전파되지 않는 문제였음. `ContentView.body` 안, 모든 `.sheet` 호출보다 바깥쪽(체인 마지막)으로 옮기고, 각 시트가 보여주는 뷰(`GuidePageView`/`ResultSheetView`/`APIKeySettingsView`)에도 개별적으로 `.environment(\.locale:)`를 한 번 더 명시해서 이중으로 보장
- **버그 수정 (실사용 중 발견 — 가이드 창 스크롤 안 됨)**: [GuidePageView.swift](AppIconGeneratorApp/GuidePageView.swift)는 `ScrollView`를 쓰고 있었지만 `.frame(minHeight:)`만 있고 `maxHeight`가 없어서, 카드 개수가 늘어난 뒤로 시트 창 자체가 화면 밖으로 계속 커지기만 하고 정작 스크롤은 안 되는 상태였음(스크롤할 여지 자체가 없어짐). `.frame(maxWidth: 680, minHeight: 480, maxHeight: 720)`로 창 크기를 유한하게 제한해서 내부 `ScrollView`가 실제로 스크롤되도록 수정
- **(후속 요청) "시스템 언어 따르기" 리셋 기능 추가**: 언어 버튼을 한 번 눌러 수동 선택이 `UserDefaults`에 저장되고 나면, 그 뒤로는 시스템 로케일이 바뀌어도(또는 처음부터 한국어인 Mac에서도 이전 테스트로 "en"이 저장돼 있으면) 계속 그 저장값만 따르는 게 당연한 설계였지만, 사용자 입장에선 "왜 계속 영어로 뜨지" 하고 헷갈릴 수 있었음. 언어 버튼에 `.contextMenu`(우클릭)로 "시스템 언어 따르기" 메뉴를 추가 — `UserDefaults.standard.removeObject(forKey:)`로 저장된 선택을 지우고 그 순간의 시스템 선호 언어로 다시 스냅샷

## 검토했으나 보류

### Icon Composer / `.icon` 포맷(iOS/iPadOS/macOS 26, Liquid Glass) 미지원
2025년 도입된 Liquid Glass 디자인 언어 이후 Apple은 레이어드 아이콘을 만드는 Icon Composer와 `.icon` 번들 포맷을 권장합니다. 현재 앱은 평평한 단일 PNG만 다루므로 최신 아이콘 스타일(레이어 분리, 반사/그림자 효과)에 대응하지 못합니다.

- 구현을 논의했으나 보류함. `.icon` 포맷은 2025년에 새로 나온 Icon Composer 전용 포맷으로, 공개된 안정적인 JSON 스키마가 없음 — 추측으로 만들면 Icon Composer/Xcode 26에서 열리지 않거나 깨지는 파일이 나올 위험이 있어 정확성을 담보할 수 없다고 판단
- 대안으로 "light/dark/tinted 레이어 PNG만 정리해서 내보내고, `.icon` 파일 자체는 Icon Composer에서 직접 조립하도록 안내"하는 절충안을 제시했으나, 사용자 요청으로 이번 라운드에서는 보류
- 향후 Apple이 `.icon` 스펙을 공식 문서로 공개하거나, 신뢰할 수 있는 레퍼런스가 확보되면 재검토

## 기타 (참고)

- `.xcodeproj`가 워킹 디렉터리에서 삭제된 상태였던 것을 `git checkout`으로 복구함
- UI 토글의 "N different sizes" 표기가 실제 생성 개수와 불일치했던 것을 수정 (iPhone 9개, iPad 10개, macOS 10개, Android 5 densities + adaptive)
