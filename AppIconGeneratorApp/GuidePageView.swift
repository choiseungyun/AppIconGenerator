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
                                "ic_launcher.png: 일반 런처 아이콘",
                                "ic_launcher_round.png: 둥근 형태 지원용 아이콘",
                                "ic_launcher-playstore.png: 스토어 업로드용 이미지"
                            ],
                            note: nil
                        )
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(guideTitle)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 620, minHeight: 560)
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
            Label(guideTitle, systemImage: topic == .ios ? "apple.logo" : "android")
                .font(.system(size: 26, weight: .bold))

            Text("아이콘 생성 후 각 플랫폼에 적용하는 방법을 정리한 안내 페이지입니다.")
                .foregroundStyle(.secondary)
        }
    }

    private func guideCard(title: String, accent: Color, steps: [String], note: String?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
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

                        Text(step)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            if let note {
                Text(note)
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
