# 앱 아이콘 자동 생성 도구 만들었습니다. AppIconGenerator 소개

안녕하세요.
앱 개발할 때 의외로 시간이 많이 드는 작업 중 하나가 아이콘 리사이징이더라고요.

원본 이미지 하나를 iOS, Android 규격에 맞춰서 파일명까지 정리하려면 생각보다 손이 많이 갑니다.
그래서 이 과정을 한 번에 처리하는 macOS 앱을 직접 만들었습니다.

오늘은 제가 만든 AppIconGenerator를 간단하게 소개해보려고 합니다.

## 이런 분들께 추천드립니다

- iOS, Android 앱 아이콘을 자주 교체하는 분
- 아이콘 규격/폴더 구조를 매번 수동으로 맞추는 분
- 디자인 시안을 빠르게 앱 리소스로 변환하고 싶은 분

## AppIconGenerator가 하는 일

원본 이미지 1장만 넣으면 Apple(iPhone, iPad, macOS, watchOS)과 Android 아이콘 세트를 자동으로 생성합니다.

핵심은 아래 3가지입니다.

- 드래그 앤 드롭으로 이미지 바로 입력
- 플랫폼별 토글로 필요한 항목만 생성
- 성공/실패 결과를 팝업으로 바로 확인

## 주요 기능

1. Apple 플랫폼 개별 생성
- iPhone
- iPad
- macOS
- watchOS

2. Android 옵션 제공
- 파일명 지정 가능 (기본값: ic_launcher)
- 대상 폴더 타입 선택 (mipmap 또는 drawable)

3. 출력 폴더 자동 제안
- 원본 이미지 위치를 기준으로 기본 출력 경로 자동 설정

## 사용 방법

1. 앱 실행
2. 원본 이미지 드래그 앤 드롭 또는 파일 선택
3. 생성할 플랫폼 선택
4. Generate files 버튼 클릭
5. 결과 팝업 확인

## 생성 결과는 이렇게 나옵니다

- Apple: AppIcon.appiconset + Contents.json
- Android: mipmap-* 또는 drawable-* + playstore

프로젝트나 팀 컨벤션에 맞춰서 필요한 폴더만 선택 생성할 수 있어서 실무에서 꽤 편합니다.

## 만들게 된 이유

앱 개발은 반복 작업을 줄일수록 속도가 확 올라가는 것 같습니다.
아이콘 생성은 필수 작업인데 수동으로 하면 실수도 나고 시간도 오래 걸려서,
아예 도구로 만들어 자동화하는 게 더 낫다고 판단했습니다.

## 배포 방식

현재 macOS에서 실행 가능하고, 아래 스크립트로 배포 파일을 만들 수 있습니다.

- DMG 생성: ./scripts/create-dmg.sh
- 코드 서명: ./scripts/sign-app.sh --dmg dist/AppIconGenerator.dmg

외부 공유를 목적으로 하신다면 Developer ID Application 인증서 + notarization까지 함께 진행하는 것을 권장드립니다.

## 프로젝트 링크

- GitHub: https://github.com/choiseungyun/AppIconGenerator

## 마무리

아이콘 작업이 자주 발생하는 분들께는 분명 시간을 아껴주는 도구가 될 거라고 생각합니다.
사용해보시고 개선 아이디어가 있으시면 편하게 의견 남겨주세요.

읽어주셔서 감사합니다.

---

## 네이버 블로그 업로드 전에 체크하면 좋은 항목

- 앱 메인 화면 캡처 2~3장
- 생성 결과 폴더 캡처 1장
- 다운로드 링크 또는 GitHub Releases 링크
- 버전 정보와 마지막 업데이트 날짜

## 태그 추천

#macOS앱 #앱개발 #아이콘생성 #iOS개발 #안드로이드개발 #개발자동화 #SwiftUI
