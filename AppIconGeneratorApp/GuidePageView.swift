import SwiftUI

struct GuidePageView: View {
    let topic: ContentView.GuideTopic
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    switch topic {
                    case .ios:
                        guideCard(
                            title: "iOS 적용 방법",
                            accent: .blue,
                            steps: [
                                "1024x1024 정사각형 원본 이미지를 준비합니다.",
                                "앱에서 이미지를 선택하거나 드래그앤드롭합니다.",
                                "Apple targets에서 iPhone, iPad, macOS, watchOS 중 필요한 항목을 선택합니다.",
                                "Generate files를 누르면 iOS용 AppIcon.appiconset이 생성됩니다.",
                                "생성된 AppIcon.appiconset 폴더를 Xcode 프로젝트의 Assets.xcassets에 넣거나 교체합니다."
                            ],
                            note: "iOS는 Xcode Assets Catalog의 App Icon 슬롯에 생성된 AppIcon.appiconset을 연결하면 됩니다."
                        )

                        guideCard(
                            title: "iOS Universal (Single Size, Xcode 14+)",
                            accent: .indigo,
                            steps: [
                                "iPhone/iPad 개별 사이즈 대신 1024x1024 한 장만 관리하고 싶다면 이 옵션을 사용합니다.",
                                "Apple targets에서 'iOS Universal (Single Size, Xcode 14+)'를 체크합니다.",
                                "생성된 iOS/AppIcon.appiconset을 Assets.xcassets에 넣고 App Icon 표시 방식을 'Single Size'로 설정합니다.",
                                "Xcode Build Settings에서 'Include All App Icon Assets'를 YES로 켜면 나머지 사이즈를 Xcode가 빌드 시 자동으로 만듭니다."
                            ],
                            note: "iPhone/iPad 항목과 별개로 독립적으로 켤 수 있으며, 둘 다 켜도 무방합니다."
                        )

                        guideCard(
                            title: "iOS 18 Dark / Tinted 아이콘",
                            accent: .indigo,
                            steps: [
                                "'iOS Universal' 옵션을 켜면 Dark/Tinted 원본 이미지를 선택할 수 있는 칸이 나타납니다.",
                                "Dark 아이콘은 어두운 배경에 어울리는 원본을 고르세요. 검정 배경으로 자동 flatten됩니다.",
                                "Tinted 아이콘은 형태(실루엣) 위주로 준비하세요. 시스템이 사용자가 고른 색을 입히도록 자동으로 흑백 변환됩니다.",
                                "둘 다 선택 사항입니다. 지정하지 않으면 기존처럼 라이트 아이콘만 생성됩니다."
                            ],
                            note: "iOS 18부터 사용자가 홈 화면에서 Light/Dark/Tinted 중 원하는 아이콘 스타일을 고를 수 있습니다."
                        )

                        guideCard(
                            title: "권장 확인사항",
                            accent: .green,
                            steps: [
                                "원본 이미지는 투명 배경이 있으면 더 깔끔합니다.",
                                "중앙 로고가 너무 가장자리에 붙지 않도록 여백을 둡니다.",
                                "실제 앱 심볼은 1024px 이상을 권장합니다."
                            ],
                            note: nil
                        )

                    case .android:
                        guideCard(
                            title: "Android 적용 방법",
                            accent: .orange,
                            steps: [
                                "1024x1024 정사각형 원본 이미지를 준비합니다.",
                                "앱에서 이미지를 선택하거나 드래그앤드롭합니다.",
                                "Android 항목을 체크하고 파일명과 target folder를 확인합니다.",
                                "Generate files를 누르면 mipmap 또는 drawable 하위에 크기별 PNG가 생성됩니다.",
                                "생성된 폴더를 Android 프로젝트의 res 디렉터리 안에 복사합니다."
                            ],
                            note: "일반적으로 app/src/main/res/mipmap-* 또는 drawable-* 구조에 맞춰 덮어쓰면 됩니다."
                        )

                        guideCard(
                            title: "적용 예시",
                            accent: .purple,
                            steps: [
                                "ic_launcher.png / ic_launcher_round.png: 밀도별(mipmap-*) 레거시 런처 아이콘",
                                "ic_launcher_foreground.png: 어댑티브 아이콘 전경 레이어 (Android 8.0+)",
                                "mipmap-anydpi-v26/ic_launcher.xml: 어댑티브 아이콘 정의 (foreground + background 조합)",
                                "values/ic_launcher_background.xml: 어댑티브 아이콘 배경 색상 리소스",
                                "ic_launcher-playstore.png: 스토어 업로드용 512x512 이미지"
                            ],
                            note: "mipmap-anydpi-v26과 values 폴더도 res 디렉터리 하위에 함께 복사해야 어댑티브 아이콘이 정상 적용됩니다."
                        )
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(Text(LocalizedStringKey(guideTitle)))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 620, maxWidth: 680, minHeight: 480, maxHeight: 720)
    }

    private var guideTitle: String {
        switch topic {
        case .ios:
            return "iOS 가이드"
        case .android:
            return "Android 가이드"
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey(guideTitle), systemImage: topic == .ios ? "apple.logo" : "android")
                .font(.system(size: 26, weight: .bold))

            Text("아이콘 생성 후 각 플랫폼에 적용하는 방법을 정리한 안내 페이지입니다.")
                .foregroundStyle(.secondary)
        }
    }

    private func guideCard(title: String, accent: Color, steps: [String], note: String?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey(title))
                .font(.system(size: 18, weight: .semibold))

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 22, height: 22)
                            .background(accent.opacity(0.15))
                            .foregroundStyle(accent)
                            .clipShape(Circle())

                        Text(LocalizedStringKey(step))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            if let note {
                Text(LocalizedStringKey(note))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(accent.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
    }
}
