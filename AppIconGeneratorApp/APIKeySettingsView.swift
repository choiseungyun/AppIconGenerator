import SwiftUI

struct APIKeySettingsView: View {
    @State var apiKey: String
    let onSave: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Gemini API 키")
                .font(.system(size: 17, weight: .semibold, design: .rounded))

            Text("Google AI Studio(aistudio.google.com)에서 발급받은 API 키를 입력하세요. 이 키는 이 Mac의 Keychain에만 저장되며, 아이콘 생성 요청 외에는 사용되지 않습니다.")
                .font(.system(size: 12.5))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            SecureField("API 키 입력", text: $apiKey)
                .textFieldStyle(.roundedBorder)

            HStack {
                if !apiKey.isEmpty {
                    Button("키 삭제", role: .destructive) {
                        apiKey = ""
                        onSave("")
                    }
                }

                Spacer()

                Button("취소") {
                    onCancel()
                }

                Button("저장") {
                    onSave(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 440)
    }
}
