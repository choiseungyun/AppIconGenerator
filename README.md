# AppIconGenerator

원본 이미지 1장을 기반으로 Apple(iPhone/iPad/macOS/watchOS) 및 Android 아이콘 세트를 자동 생성하는 macOS 데스크탑 앱입니다.

## 요구 사항

- macOS 13+
- Xcode 15+
- Swift 5.9+

## 실행 방법

### 1) Xcode 프로젝트로 실행

1. Xcode 실행
2. `File > Open...`에서 `AppIconGenerator.xcodeproj` 선택
3. Scheme `AppIconGenerator` 선택
4. Run (`Cmd + R`)

## 주요 기능

- 드래그 앤 드롭 또는 파일 선택으로 원본 이미지 입력
- 이미지 미리보기 표시
- Apple 플랫폼별 개별 생성 토글
  - iPhone
  - iPad
  - macOS
  - watchOS
  - iOS Universal (Single Size, Xcode 14+)
- Android 생성 옵션
  - 파일명 지정 (`ic_launcher` 기본값)
  - 대상 폴더 타입 선택 (`mipmap` / `drawable`)
- 스토어 등록 이미지(원본 이미지 중앙 배치 placeholder) 생성 옵션
- Gemini AI로 원본 이미지 없이 프롬프트만으로 아이콘 자동 생성
  - Apple: App Store Connect macOS/iPhone/iPad 스크린샷 필수 사이즈
  - Android: Play Console feature graphic + 스크린샷 필수 사이즈
- 성공/실패 결과를 플랫폼별 아이콘 · 경로 · Finder 바로가기가 포함된 결과 시트로 표시
- 원본 이미지 선택 시 기본 출력 폴더 자동 제안
  - `원본파일_디렉토리/원본파일명(확장자 제외)`
- 다국어 지원 (한국어 / 영어) — 기본은 macOS 시스템 언어를 따르고, 헤더의 언어 버튼으로 언제든 수동 전환 가능 (선택은 저장됨)

## 사용 방법

1. 원본 이미지 선택 또는 드롭
2. 필요한 플랫폼 체크
3. 출력 폴더 확인(필요 시 `Choose`로 변경)
4. `Generate files` 클릭
5. 결과 팝업에서 성공/실패 내용 확인

## 출력 구조 예시

```text
출력폴더/
  iPhone/
    AppIcon.appiconset/
      Contents.json
      iphone-20.0x20.0@2x.png
      ...
      ios-marketing-1024.0x1024.0@1x.png   # App Store Connect 심사용, 알파 채널 제거됨
  iPad/
    AppIcon.appiconset/
      Contents.json
      ipad-20.0x20.0@1x.png
      ...
      ios-marketing-1024.0x1024.0@1x.png
  macOS/
    AppIcon.appiconset/
      Contents.json
      macos-16.0x16.0@1x.png
      ...
  watchOS/
    AppIcon.appiconset/
      Contents.json
      watchos-24.0x24.0@2x.png
      ...
  Android/
    mipmap-mdpi/
      ic_launcher.png
      ic_launcher_round.png
      ic_launcher_foreground.png           # 어댑티브 아이콘 전경 레이어
    mipmap-hdpi/
      ic_launcher.png
      ic_launcher_round.png
      ic_launcher_foreground.png
    ...
    mipmap-anydpi-v26/
      ic_launcher.xml                      # 어댑티브 아이콘 정의 (API 26+)
      ic_launcher_round.xml
    values/
      ic_launcher_background.xml           # 어댑티브 아이콘 배경 색상
    playstore/
      ic_launcher-playstore.png
  iOS/                                     # "iOS Universal (Single Size)" 옵션 켰을 때만 생성
    AppIcon.appiconset/
      Contents.json
      AppIcon-1024.png
      AppIcon-1024-dark.png                # Dark 아이콘 지정 시에만 생성 (검정 배경 flatten)
      AppIcon-1024-tinted.png              # Tinted 아이콘 지정 시에만 생성 (흑백 변환)
  StoreAssets/                             # "스토어 등록 이미지" 옵션 켰을 때만 생성
    Apple/
      appstore-mac-1280x800.png
      appstore-mac-1440x900.png
      appstore-mac-2560x1600.png
      appstore-mac-2880x1800.png
      appstore-iphone-6.9in-1320x2868.png
      appstore-ipad-13in-2064x2752.png
    Android/
      playstore-feature-graphic-1024x500.png
      playstore-phone-screenshot-1080x1920.png
```

### 추가된 최신 규격 대응

- **App Store 마케팅 아이콘**: iPhone/iPad `AppIcon.appiconset`에 `ios-marketing`(1024x1024, 알파 없음) 아이콘을 자동 포함합니다. App Store Connect는 투명도가 있는 1024 아이콘을 거부하므로, 해당 이미지는 흰 배경으로 flatten되어 생성됩니다.
- **Android 어댑티브 아이콘**: Android 8.0(API 26)+ 표준인 `mipmap-anydpi-v26/ic_launcher.xml` + `_foreground.png`(safe zone 66% 축소) + `values/ic_launcher_background.xml` 조합을 함께 생성합니다. 레거시 `mipmap-*/ic_launcher.png`는 하위 호환을 위해 계속 생성됩니다.
- **iOS Universal (Single Size, Xcode 14+)**: 옵션을 켜면 1024x1024 이미지 한 장 + `Contents.json`(idiom `universal`)만 있는 `iOS/AppIcon.appiconset`을 별도로 생성합니다. Xcode 프로젝트의 Asset Catalog에서 App Icon을 "Single Size"로 설정하고, Build Settings의 **Include All App Icon Assets**(`ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS`)를 `YES`로 켜면, 빌드 시 Xcode가 나머지 iPhone/iPad 사이즈를 자동으로 만들어줍니다. iPhone/iPad 개별 다중 사이즈 세트를 관리할 필요가 없어지는 최신(Xcode 14+) 권장 방식입니다.
- **iOS 18 Dark / Tinted 아이콘**: "iOS Universal" 옵션을 켜면 Dark/Tinted 원본 이미지를 선택 사항으로 지정할 수 있습니다. 지정하면 `Contents.json`에 `appearances`(`luminosity: dark` / `luminosity: tinted`) variant가 추가됩니다. Dark는 검정 배경으로 flatten, Tinted는 시스템이 사용자가 고른 색을 입힐 수 있도록 자동으로 흑백(grayscale)으로 변환해서 저장합니다. 미지정 시 기존처럼 라이트 아이콘만 생성됩니다.
- **스토어 등록 이미지(placeholder)**: 앱 아이콘이 아니라 App Store Connect / Play Console에 올리는 스크린샷·그래픽 자산의 필수 사이즈에 맞춘 이미지입니다. 실제 스크린샷은 아니지만, 흰 배경 중앙에 원본 이미지를 짧은 변의 60% 크기로 배치해서 정확한 픽셀 크기와 로고가 어떻게 보이는지 함께 확인할 수 있습니다. 파일명에 용도와 픽셀 크기가 표기되어 있어 어디에 쓰는 이미지인지 바로 구분할 수 있습니다.
  - Apple: macOS 4종(1280x800 / 1440x900 / 2560x1600 / 2880x1800 중 실제 캡처 해상도에 맞는 것 하나만 업로드), iPhone 6.9형(1320x2868), iPad 13형(2064x2752) — App Store Connect는 각 기기군당 하나만 업로드하면 나머지를 자동 스케일링합니다.
  - Android: Play Console feature graphic(1024x500, 필수), phone 스크린샷(1080x1920)

## Xcode 앱 아이콘 반영

- 앱 자체 아이콘은 `Assets.xcassets/AppIcon.appiconset`을 사용합니다.
- Xcode Build Settings에서 `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`로 설정되어 있어야 합니다.

## DMG 배포(요약)

1. Xcode로 `Release` 빌드 또는 Archive
2. `.app` 파일 준비
3. `hdiutil`로 `.dmg` 생성
4. (권장) 코드 서명 + notarization + staple

## create-dmg 배포 스크립트

프로젝트에 create-dmg 기반 자동 배포 스크립트가 포함되어 있습니다.

1. create-dmg 설치

```bash
brew install create-dmg
```

2. 실행 권한 부여(최초 1회)

```bash
chmod +x scripts/create-dmg.sh
```

3. Release 빌드 + DMG 생성

```bash
./scripts/create-dmg.sh
```

4. 빌드 생략하고 기존 .app으로 DMG만 생성

```bash
./scripts/create-dmg.sh --no-build
```

생성 결과물 위치:

- `dist/AppIconGenerator.dmg`

문제가 발생할 때(예: xcodebuild requires Xcode):

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## 코드 사이닝(Code Signing)

앱 신뢰성 검증을 위해 코드 서명을 적용할 수 있습니다.

1. 서명 스크립트 실행 권한 부여(최초 1회)

```bash
chmod +x scripts/sign-app.sh
```

2. 기본 경로의 Release 앱 서명 + 검증

```bash
./scripts/sign-app.sh
```

3. DMG까지 함께 서명

```bash
./scripts/sign-app.sh --dmg dist/AppIconGenerator.dmg
```

참고:

- 외부 배포(게이트키퍼 통과) 목적이면 `Developer ID Application` 인증서를 사용해야 합니다.
- `Apple Development` 인증서는 개발/테스트 목적에 적합합니다.
- 외부 배포 완성 단계에서는 notarization + staple을 추가로 수행하세요.

## 릴리스 체크리스트

블로그/외부 공유 전에 아래 순서를 권장합니다.

1. Release 빌드

```bash
./scripts/create-dmg.sh
```

2. 코드 서명

```bash
./scripts/sign-app.sh --dmg dist/AppIconGenerator.dmg
```

3. 검증

```bash
codesign --verify --deep --strict --verbose=2 build/DerivedData/Build/Products/Release/AppIconGenerator.app
codesign --verify --verbose=2 dist/AppIconGenerator.dmg
spctl -a -vv build/DerivedData/Build/Products/Release/AppIconGenerator.app
```

4. (권장) notarization + staple

- Gatekeeper 경고 없이 배포하려면 notarization이 필요합니다.

## 통합 테스트

`IconGenerator`/`IconSpecs`는 SwiftUI에 의존하지 않으므로, Xcode 앱을 실행하지 않고도 생성 파이프라인 전체(리사이즈, PNG/Contents.json/adaptive icon XML 생성)를 검증할 수 있습니다.

```bash
./scripts/run-integration-tests.sh
```

`swiftc`로 `IconSpecs.swift` + `IconGenerator.swift` + `IntegrationTests/main.swift`를 컴파일해 실행하며, 다음을 검증합니다.

- 플랫폼별 생성 파일 개수 및 `Contents.json` 내용 (iPhone 9 / iPad 10 / macOS 10 / watchOS 8)
- `ios-marketing` 1024 아이콘의 알파 채널 제거 여부
- `iOS Universal (Single Size)` 아이콘의 idiom/platform/size, Dark/Tinted appearance variant 및 흑백 변환·검정 배경 flatten 여부
- Android 어댑티브 아이콘(`mipmap-anydpi-v26/*.xml`, foreground, `values/ic_launcher_background.xml`) 및 커스텀 파일명/타겟 폴더(mipmap ↔ drawable)
- 스토어 등록 이미지의 파일 존재 여부·픽셀 크기·알파 채널 제거 여부·원본 이미지 중앙 배치(중앙 픽셀은 흰색이 아니고 모서리는 흰 배경 유지) 검증
- 플랫폼 미선택, 원본 이미지 최소 크기(1024) 미달 등 에러 케이스
- 결과 로그의 `kind`(플랫폼/종류를 나타내는 언어 독립적 값)가 실제 생성된 플랫폼과 일치하는지 검증

Xcode 없이 커맨드라인 툴(`swiftc`, macOS SDK)만으로 동작하므로 CI에도 바로 사용할 수 있습니다. 단, 드래그앤드롭·버튼 클릭 등 실제 UI 동작은 이 테스트로 검증되지 않으며, 그 부분은 Xcode에서 직접 실행해 확인해야 합니다.

## AI로 아이콘 생성 (Gemini)

원본 이미지를 준비하지 못했어도, 문장으로 설명만 하면 Gemini 이미지 생성 모델이 아이콘을 만들어서 기존 파이프라인에 그대로 넣어줍니다.

1. 헤더 아래 "AI로 생성" 바에서 열쇠 아이콘을 눌러 Gemini API 키를 입력합니다.
   - [Google AI Studio](https://aistudio.google.com)에서 발급받을 수 있습니다.
   - 키는 이 Mac의 **Keychain**에만 저장되며, 앱 밖으로 나가지 않습니다.
2. 프롬프트를 입력하고(예: "로켓 모양의 미니멀한 플랫 아이콘, 파란색 배경") `생성`을 누릅니다.
3. 생성이 끝나면 자동으로 원본 이미지 자리에 채워지고, 출력 폴더는 `~/Downloads/AppIcon`으로 기본 설정됩니다(필요 시 변경 가능).
4. 이후 흐름(플랫폼 선택 → Generate files)은 파일을 직접 올렸을 때와 동일합니다.

참고:
- Gemini가 반환한 이미지가 정사각형이 아니거나 1024px보다 작으면, 중앙 크롭 + 흰 배경 업스케일로 자동 보정합니다.
- 네트워크/API 키/컨텐츠 정책 등으로 실패하면 에러 메시지가 바로 표시됩니다.
- 사용된 모델 이름(`gemini-2.5-flash-image`)은 [GeminiIconService.swift](AppIconGeneratorApp/GeminiIconService.swift)에 상수로 있습니다. Google이 모델을 교체하면 이 값을 최신 이미지 생성 모델명으로 바꿔야 합니다.

## 다국어 지원 (한국어 / 영어)

기본값은 macOS 시스템 언어를 따릅니다(한국어 로케일이면 한국어, 그 외에는 영어). 헤더 오른쪽 위의 언어 버튼("EN"/"한글")을 누르면 앱 재시작 없이 즉시 언어가 바뀌고, 그 선택은 다음 실행에도 유지됩니다. 버튼을 **우클릭**하면 저장된 수동 선택을 지우고 그 순간의 시스템 언어로 되돌리는 "시스템 언어 따르기" 메뉴가 나옵니다.

- [AppLanguage.swift](AppIconGeneratorApp/AppLanguage.swift) — 현재 언어 상태를 관리합니다. 사용자가 아직 버튼을 누르지 않았으면 시스템 로케일을, 눌렀으면 `UserDefaults`에 저장된 선택을 따릅니다.
- [Localizable.xcstrings](AppIconGeneratorApp/Localizable.xcstrings) — Xcode String Catalog. 화면 문구, 가이드 페이지, 결과/에러 메시지가 `ko`/`en` 양쪽 번역과 함께 등록되어 있습니다(123개 수동 등록 키 + Xcode가 자동 추출한 스텝 번호 배지 1개).
- 언어 버튼을 누르면 `ContentView.body`에 적용된 `.environment(\.locale:)`가 즉시 갱신되어 메인 화면이 바뀝니다. `.sheet`로 뜨는 가이드/결과/API 키 창은 별도의 프레젠테이션 컨텍스트라 상위 environment를 안정적으로 물려받지 않는 경우가 있어, 각 시트 콘텐츠에도 `.environment(\.locale:)`를 개별적으로 한 번 더 명시해서 이중으로 보장합니다.
- `IconGenerator`/`StoreAssetGenerator`/`GeminiIconService`처럼 View가 아닌 코드가 만드는 결과 로그·에러 메시지는 SwiftUI environment를 볼 수 없어서, `AppLanguage.localized(...)`로 현재 선택된 언어를 명시적으로 넘겨 로컬라이즈합니다. `NSOpenPanel.title`(AppKit)도 같은 이유로 `AppLanguage.localized(forKey:)`를 씁니다.
- 결과 화면(ResultSheetView)은 예전엔 로그 문자열 안의 한국어 키워드(예: `"어댑티브"`, `"iPhone"`)를 찾아서 아이콘을 골랐는데, 이 방식은 언어가 바뀌면 그대로 깨집니다. 그래서 [GenerationLogEntry.swift](AppIconGeneratorApp/GenerationLogEntry.swift)에 언어와 무관한 `kind`(열거형)를 추가하고, `IconGenerator`/`StoreAssetGenerator`는 이제 `[GenerationLogEntry]`(kind + 로컬라이즈된 메시지 + 경로)를 반환합니다. 아이콘/색상 선택은 `kind`만 보고 판단하므로 언어에 영향받지 않습니다.
- 동적 메시지(파일 경로, 크기, 에러 상세 등이 들어가는 문장)는 Swift의 암묵적 문자열 보간 대신 `String(format:)` + 명시적 `%@`/`%ld` 포맷 문자열을 사용합니다. Xcode 없이 이 저장소를 다루는 환경에서도 String Catalog 키가 정확히 일치하는지 스크립트로 직접 검증할 수 있도록 하기 위함입니다.
- `Text(someString)`처럼 문자열 **변수**를 표시하는 곳은 SwiftUI가 자동으로 번역 테이블을 찾지 않습니다(리터럴만 자동 인식). 이런 곳은 `Text(LocalizedStringKey(someString))`으로 명시적으로 감싸서 번역이 실제로 적용되도록 처리했습니다.
- 언어가 화면에 안 보이면: 이전에 언어 버튼으로 저장해둔 수동 선택이 남아있을 수 있습니다. 버튼을 우클릭해 "시스템 언어 따르기"를 누르거나, 터미널에서 `defaults delete kr.weare.AppIconGenerator AppIconGenerator.selectedLanguage` 실행 후 재시작하세요.

## App Sandbox / Entitlements

[AppIconGenerator.entitlements](AppIconGeneratorApp/AppIconGenerator.entitlements)에 Mac App Store 배포에 필요한 최소 권한만 선언되어 있습니다.

| Entitlement | 이유 |
|---|---|
| `com.apple.security.app-sandbox` | Mac App Store 제출 필수 요건 |
| `com.apple.security.network.client` | Gemini API 호출(`URLSession`)에 필요 |
| `com.apple.security.files.user-selected.read-write` | `NSOpenPanel`로 고른 원본 이미지/출력 폴더 읽기·쓰기 |
| `com.apple.security.files.downloads.read-write` | AI 생성 아이콘의 기본 출력 폴더(`~/Downloads/AppIcon`)가 패널을 거치지 않고 코드로 지정되므로 필요 |

Debug/Release 두 빌드 설정 모두 `CODE_SIGN_ENTITLEMENTS`로 이 파일을 참조합니다.

## 주의 사항

- 원본 이미지는 최소 1024x1024 이상이어야 합니다.
- 정사각형 이미지를 권장합니다.
- 아이콘이 바로 안 보이면 macOS 캐시 영향일 수 있으니 앱 재실행/클린 빌드를 먼저 시도하세요.
