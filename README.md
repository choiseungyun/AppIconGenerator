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
- Android 생성 옵션
  - 파일명 지정 (`ic_launcher` 기본값)
  - 대상 폴더 타입 선택 (`mipmap` / `drawable`)
- 성공/실패 결과를 커스텀 디자인 팝업으로 표시
- 원본 이미지 선택 시 기본 출력 폴더 자동 제안
  - `원본파일_디렉토리/원본파일명(확장자 제외)`

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
  iPad/
    AppIcon.appiconset/
      Contents.json
      ipad-20.0x20.0@1x.png
      ...
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
    mipmap-hdpi/
      ic_launcher.png
      ic_launcher_round.png
    ...
    playstore/
      ic_launcher-playstore.png
```

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

## 주의 사항

- 원본 이미지는 최소 1024x1024 이상이어야 합니다.
- 정사각형 이미지를 권장합니다.
- 아이콘이 바로 안 보이면 macOS 캐시 영향일 수 있으니 앱 재실행/클린 빌드를 먼저 시도하세요.
