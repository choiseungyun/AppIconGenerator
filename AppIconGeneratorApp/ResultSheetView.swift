import AppKit
import SwiftUI

struct GenerationResultRow: Identifiable {
    let id = UUID()
    let icon: String
    let accent: Color
    let title: String
    let path: String?
}

extension GenerationResultRow {
    static func from(_ entries: [GenerationLogEntry]) -> [GenerationResultRow] {
        entries.map { entry in
            let (icon, accent) = style(for: entry.kind)
            return GenerationResultRow(icon: icon, accent: accent, title: entry.message, path: entry.path)
        }
    }

    private static func style(for kind: GenerationLogKind) -> (icon: String, accent: Color) {
        switch kind {
        case let .appleIconSet(platform):
            switch platform {
            case .iPhone:
                return ("iphone", .blue)
            case .iPad:
                return ("ipad", .blue)
            case .macOS:
                return ("desktopcomputer", .gray)
            case .watchOS:
                return ("applewatch", .pink)
            case .iOS:
                return ("square.on.square", .teal)
            }
        case .androidIconSet:
            return ("square.stack.3d.up", .green)
        case .androidAdaptiveIcon:
            return ("square.stack.3d.up.fill", .green)
        case .iosUniversalIcon:
            return ("square.on.square", .teal)
        case .appleStoreAssets:
            return ("app.badge", .indigo)
        case .androidStoreAssets:
            return ("photo.on.rectangle.angled", .orange)
        case .notice:
            return ("exclamationmark.triangle.fill", .orange)
        case .warning:
            return ("info.circle.fill", .secondary)
        }
    }
}

struct ResultSheetView: View {
    let isSuccess: Bool
    let rows: [GenerationResultRow]
    let errorMessage: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    if isSuccess {
                        if rows.isEmpty {
                            emptyState
                        } else {
                            VStack(spacing: 10) {
                                ForEach(rows) { row in
                                    resultRow(row)
                                }
                            }
                        }
                    } else {
                        errorCard
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(isSuccess ? "생성 완료" : "생성 실패")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("확인") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 640, minHeight: 520)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .font(.system(size: 36))
                .foregroundStyle(isSuccess ? Color.green : Color.red)

            VStack(alignment: .leading, spacing: 4) {
                Text(isSuccess ? "아이콘/이미지 생성이 완료되었습니다" : "생성 중 오류가 발생했습니다")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))

                if isSuccess {
                    Text(String(format: String(localized: "%ld개 항목 생성됨"), rows.count))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var emptyState: some View {
        Text("생성된 항목이 없습니다.")
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
    }

    private var errorCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)

            Text(errorMessage ?? String(localized: "알 수 없는 오류입니다."))
                .font(.system(size: 13))
                .textSelection(.enabled)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.red.opacity(0.25), lineWidth: 1)
        )
    }

    private func resultRow(_ row: GenerationResultRow) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: row.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(row.accent)
                .frame(width: 24, height: 24)
                .background(row.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(row.title)
                    .font(.system(size: 13.5, weight: .medium))

                if let path = row.path {
                    Text(path)
                        .font(.system(size: 11.5, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
            }

            Spacer(minLength: 8)

            if let path = row.path {
                Button {
                    revealInFinder(path: path)
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
                .help("Finder에서 보기")
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func revealInFinder(path: String) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }
}
