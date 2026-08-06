import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum GeminiIconServiceError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case requestFailed(statusCode: Int, message: String)
    case noImageInResponse
    case imageProcessingFailed

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return AppLanguage.localized("Gemini API 키가 설정되지 않았습니다.")
        case .invalidResponse:
            return AppLanguage.localized("Gemini 서버 응답을 처리할 수 없습니다.")
        case let .requestFailed(statusCode, message):
            if statusCode == 429 {
                let template = AppLanguage.localized("Gemini 무료 할당량을 초과했습니다. %@")
                return String(format: template, message)
            }
            let template = AppLanguage.localized("Gemini 요청이 실패했습니다 (HTTP %ld): %@")
            return String(format: template, statusCode, message)
        case .noImageInResponse:
            return AppLanguage.localized("Gemini가 이미지를 반환하지 않았습니다. 프롬프트를 조금 더 구체적으로 적어보세요.")
        case .imageProcessingFailed:
            return AppLanguage.localized("생성된 이미지를 처리하는 데 실패했습니다.")
        }
    }
}

/// Gemini 이미지 생성 모델을 호출해서 텍스트 프롬프트만으로 앱 아이콘 원본 이미지를 만든다.
/// 응답 이미지는 정사각형/최소 1024px 요구사항에 맞춰 후처리한 뒤 임시 PNG로 저장하고,
/// 그 파일 URL을 기존 아이콘 생성 파이프라인의 `sourceURL`로 그대로 재사용한다.
///
/// 참고: 모델 이름(`model`)은 Google이 새 버전을 내놓으면 바뀔 수 있다. 요청이 계속
/// 404/모델없음 오류로 실패하면 이 값을 최신 이미지 생성 모델 이름으로 바꿔야 한다.
struct GeminiIconService {
    private let model = "gemini-2.5-flash-image"
    private let minimumSize = 1024

    func generateIconSourceFile(prompt: String, apiKey: String) async throws -> URL {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw GeminiIconServiceError.missingAPIKey
        }

        let rawImage = try await requestImage(prompt: prompt, apiKey: trimmedKey)

        guard let normalized = normalizedSquareIcon(from: rawImage) else {
            throw GeminiIconServiceError.imageProcessingFailed
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("gemini-icon-\(UUID().uuidString).png")
        try writePNG(normalized, to: tempURL)

        return tempURL
    }

    private func requestImage(prompt: String, apiKey: String) async throws -> CGImage {
        guard let url = URL(
            string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        ) else {
            throw GeminiIconServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let iconPrompt = """
        Generate a single square app icon illustration. No text, no watermark, no border, \
        no mockup device frame. Centered composition, flat modern icon design, the background \
        fills the entire square edge-to-edge with no transparency.

        Subject: \(prompt)
        """

        let body = GeminiGenerateContentRequest(contents: [.init(parts: [.init(text: iconPrompt)])])
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiIconServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let message = friendlyErrorMessage(statusCode: httpResponse.statusCode, rawBody: data)
            throw GeminiIconServiceError.requestFailed(statusCode: httpResponse.statusCode, message: message)
        }

        let decoded = try JSONDecoder().decode(GeminiGenerateContentResponse.self, from: data)

        guard let base64 = decoded.candidates?
            .first?.content?.parts?
            .first(where: { $0.inlineData != nil })?.inlineData?.data,
            let imageData = Data(base64Encoded: base64),
            let nsImage = NSImage(data: imageData) else {
            throw GeminiIconServiceError.noImageInResponse
        }

        var rect = CGRect(origin: .zero, size: nsImage.size)
        guard let cgImage = nsImage.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
            throw GeminiIconServiceError.noImageInResponse
        }

        return cgImage
    }

    /// Google API 표준 에러 바디({"error": {"code", "message", "status"}})에서 사람이 읽을 수
    /// 있는 짧은 메시지만 뽑아낸다. 파싱에 실패하면 원본 JSON 전체를 UI에 노출하지 않도록
    /// 상태 코드만 보여준다. 429(RESOURCE_EXHAUSTED)면 재시도 대기시간도 함께 안내한다.
    private func friendlyErrorMessage(statusCode: Int, rawBody: Data) -> String {
        let serverErrorTemplate = AppLanguage.localized("서버 오류 (HTTP %ld)")

        guard let decoded = try? JSONDecoder().decode(GeminiErrorResponse.self, from: rawBody) else {
            return String(format: serverErrorTemplate, statusCode)
        }

        var message = decoded.error?.message ?? String(format: serverErrorTemplate, statusCode)

        if statusCode == 429, let retryDelay = extractRetryDelay(from: rawBody) {
            let retryTemplate = AppLanguage.localized("(%@ 후 다시 시도해보세요)")
            message += " " + String(format: retryTemplate, retryDelay)
        }

        return message
    }

    private func extractRetryDelay(from data: Data) -> String? {
        guard let text = String(data: data, encoding: .utf8),
              let range = text.range(of: #""retryDelay"\s*:\s*"[^"]+""#, options: .regularExpression) else {
            return nil
        }

        let match = text[range]
        guard let valueRange = match.range(of: #"[0-9]+[a-z]+"#, options: .regularExpression) else {
            return nil
        }

        return String(match[valueRange])
    }

    /// 가운데를 기준으로 정사각형으로 크롭하고, 최소 1024px보다 작으면 업스케일한다.
    private func normalizedSquareIcon(from image: CGImage) -> CGImage? {
        let side = max(min(image.width, image.height), 1)
        let cropX = (image.width - side) / 2
        let cropY = (image.height - side) / 2
        let squareImage = image.cropping(to: CGRect(x: cropX, y: cropY, width: side, height: side)) ?? image

        let targetSize = max(side, minimumSize)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: targetSize,
            height: targetSize,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return nil
        }

        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: targetSize, height: targetSize))
        context.interpolationQuality = .high
        context.draw(squareImage, in: CGRect(x: 0, y: 0, width: targetSize, height: targetSize))

        return context.makeImage()
    }

    private func writePNG(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw GeminiIconServiceError.imageProcessingFailed
        }

        CGImageDestinationAddImage(destination, image, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw GeminiIconServiceError.imageProcessingFailed
        }
    }
}

private struct GeminiGenerateContentRequest: Encodable {
    struct Content: Encodable {
        struct Part: Encodable {
            let text: String
        }
        let parts: [Part]
    }
    let contents: [Content]
}

private struct GeminiErrorResponse: Decodable {
    struct ErrorBody: Decodable {
        let code: Int?
        let message: String?
        let status: String?
    }
    let error: ErrorBody?
}

private struct GeminiGenerateContentResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable {
                struct InlineData: Decodable {
                    let mimeType: String?
                    let data: String?
                }
                let inlineData: InlineData?
            }
            let parts: [Part]?
        }
        let content: Content?
    }
    let candidates: [Candidate]?
}
