import SwiftUI
import UniformTypeIdentifiers
import AppKit

@main
struct AppIconGeneratorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 1120, height: 820)
        }
        .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    enum ResultPopupStyle {
        case success
        case failure

        var title: String {
            switch self {
            case .success:
                return "생성 성공"
            case .failure:
                return "생성 실패"
            }
        }

        var icon: String {
            switch self {
            case .success:
                return "checkmark.seal.fill"
            case .failure:
                return "xmark.octagon.fill"
            }
        }

        var accent: Color {
            switch self {
            case .success:
                return .cyan
            case .failure:
                return .red
            }
        }
    }

    enum GuideTopic: String, Identifiable {
        case ios
        case android

        var id: String { rawValue }
    }

    @State private var sourceImageURL: URL?
    @State private var outputDirectoryURL: URL?
    @State private var includeIPhone = true
    @State private var includeIPad = true
    @State private var includeMacOS = true
    @State private var includeWatchOS = true
    @State private var includeAndroid = true
    @State private var androidBaseFileName = "ic_launcher"
    @State private var androidTargetFolder = "mipmap"
    @State private var isGenerating = false
    @State private var isDropTargeted = false
    @State private var activeGuideTopic: GuideTopic?
    @State private var resultPopupStyle: ResultPopupStyle = .success
    @State private var resultPopupMessage = ""
    @State private var showingResultPopup = false

    private let androidFolderOptions = ["mipmap", "drawable"]
    private let dropZoneSize: CGFloat = 520

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(alignment: .leading, spacing: 20) {
                headerSection

                HStack(alignment: .top, spacing: 18) {
                    dropZone
                    optionsPanel
                }

                hintStrip
            }
            .padding(26)

            if showingResultPopup {
                resultPopupOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .background(WindowConfigurationView(size: CGSize(width: 1120, height: 820)))
        .sheet(item: $activeGuideTopic) { topic in
            GuidePageView(topic: topic)
        }
        .animation(.easeInOut(duration: 0.18), value: showingResultPopup)
    }

    private var resultPopupOverlay: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: resultPopupStyle.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(resultPopupStyle.accent)

                    Text(resultPopupStyle.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()
                }

                ScrollView {
                    Text(resultPopupMessage)
                        .font(.system(size: 14.5))
                        .foregroundStyle(.white.opacity(0.86))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(height: 180)
                .padding(12)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                )

                HStack {
                    Spacer()
                    Button("확인") {
                        showingResultPopup = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(resultPopupStyle.accent)
                    .controlSize(.large)
                }
            }
            .padding(20)
            .frame(width: 520)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.10, blue: 0.16), Color(red: 0.10, green: 0.13, blue: 0.20)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 28, x: 0, y: 20)
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.12),
                    Color(red: 0.08, green: 0.12, blue: 0.19),
                    Color(red: 0.13, green: 0.17, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.cyan.opacity(0.16))
                .frame(width: 420, height: 420)
                .blur(radius: 18)
                .offset(x: -330, y: -250)

            Circle()
                .fill(Color.blue.opacity(0.14))
                .frame(width: 520, height: 520)
                .blur(radius: 24)
                .offset(x: 420, y: 290)

            RoundedRectangle(cornerRadius: 200, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .frame(width: 560, height: 260)
                .blur(radius: 10)
                .offset(x: 180, y: -300)
        }
        .ignoresSafeArea()
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("App Icon Generator")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("원본 이미지를 넣으면 iOS, Android, macOS, watchOS용 아이콘 세트를 한 번에 생성합니다.")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.74))

                HStack(spacing: 10) {
                    CapsuleTag(title: "Drag & Drop", icon: "arrow.down.doc")
                    CapsuleTag(title: "Preview", icon: "photo")
                    CapsuleTag(title: "Generate", icon: "wand.and.stars")
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                Text("Mac Desktop Tool")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.08), in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))

                Text("Dark Modern UI")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
        .padding(.horizontal, 6)
    }

    private var hintStrip: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(.cyan)
            Text("1024x1024 정사각형 이미지를 추천합니다. 이미지 선택 시 기본 output folder는 파일명 폴더로 자동 설정됩니다.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var dropZone: some View {
        Button {
            sourceImageURL = chooseImageFile()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)

                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                    .foregroundStyle(isDropTargeted ? Color.cyan : Color.white.opacity(0.22))

                if let previewImage = previewImage {
                    Image(nsImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(34)
                        .shadow(color: .black.opacity(0.22), radius: 28, x: 0, y: 14)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 78, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.cyan, Color.blue, Color.indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(spacing: 8) {
                            Text("Click or drag image file")
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)

                            Text("1024 x 1024")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.white.opacity(0.09), in: Capsule())
                                .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
                        }

                        if let sourceImageURL {
                            Text(sourceImageURL.lastPathComponent)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.82))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 360)
            .frame(width: dropZoneSize, height: dropZoneSize)
            .compositingGroup()
            .shadow(color: .black.opacity(0.28), radius: 30, x: 0, y: 18)
        }
        .buttonStyle(.plain)
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted, perform: handleFileDrop(providers:))
    }

    private var previewImage: NSImage? {
        guard let sourceImageURL else { return nil }
        return NSImage(contentsOf: sourceImageURL)
    }

    private var optionsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            PlatformCard(
                title: "Apple targets",
                symbol: "apple.logo",
                actionTitle: "iOS 가이드 보기",
                action: { activeGuideTopic = .ios }
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("iPhone  - 11 different sizes and files", isOn: $includeIPhone)
                    Toggle("iPad  - 13 different sizes and files", isOn: $includeIPad)
                    Toggle("macOS  - 11 different sizes and files", isOn: $includeMacOS)
                    Toggle("watchOS  - 8 different sizes and files", isOn: $includeWatchOS)
                }
                .toggleStyle(.checkbox)
                .font(.system(size: 14.5, weight: .medium))
                .tint(.cyan)
            }

            PlatformCard(
                title: "Android",
                symbol: "square.stack.3d.up",
                actionTitle: "Android 가이드 보기",
                action: { activeGuideTopic = .android }
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle("Android  - 4 different sizes and files", isOn: $includeAndroid)
                        .toggleStyle(.checkbox)
                        .font(.system(size: 14.5, weight: .medium))
                        .tint(.cyan)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Text("File name")
                                .foregroundStyle(.white.opacity(0.72))
                                .frame(width: 84, alignment: .leading)
                            TextField("ic_launcher", text: $androidBaseFileName)
                                .textFieldStyle(.roundedBorder)
                                .disabled(!includeAndroid)
                        }

                        HStack(spacing: 10) {
                            Text("Target folders")
                                .foregroundStyle(.white.opacity(0.72))
                                .frame(width: 84, alignment: .leading)
                            Picker("", selection: $androidTargetFolder) {
                                ForEach(androidFolderOptions, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .disabled(!includeAndroid)
                        }
                    }
                }
                .padding(.top, 2)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Output folder")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.72))
                    Spacer()
                    Button("Choose") {
                        outputDirectoryURL = chooseOutputFolder()
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }

                Text(outputDirectoryURL?.path ?? "Not selected")
                    .font(.system(size: 12.5))
                    .foregroundStyle(outputDirectoryURL == nil ? .white.opacity(0.48) : .white.opacity(0.88))
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.white.opacity(0.10), lineWidth: 1)
                    )
            }

            HStack(spacing: 8) {
                Button {
                    generateIcons()
                } label: {
                    Label(isGenerating ? "Generating..." : "Generate files", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!canGenerate)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.cyan)
            }
        }
        .frame(width: 380)
    }

    private var canGenerate: Bool {
        !isGenerating && sourceImageURL != nil && outputDirectoryURL != nil && (includeIPhone || includeIPad || includeMacOS || includeWatchOS || includeAndroid)
    }

    private func generateIcons() {
        guard let sourceImageURL, let outputDirectoryURL else {
            return
        }

        isGenerating = true
        defer { isGenerating = false }

        do {
            let generator = IconGenerator()
            let result = try generator.generate(
                sourceURL: sourceImageURL,
                outputDirectory: outputDirectoryURL,
                includeIPhone: includeIPhone,
                includeIPad: includeIPad,
                includeMacOS: includeMacOS,
                includeWatchOS: includeWatchOS,
                includeAndroid: includeAndroid,
                androidBaseFileName: sanitizedAndroidBaseName,
                androidTargetRoot: androidTargetFolder
            )

            resultPopupStyle = .success
            resultPopupMessage = result.joined(separator: "\n")
            if resultPopupMessage.isEmpty {
                resultPopupMessage = "아이콘 생성이 완료되었습니다."
            }
            showingResultPopup = true
        } catch {
            resultPopupStyle = .failure
            resultPopupMessage = error.localizedDescription
            showingResultPopup = true
        }
    }

    private var sanitizedAndroidBaseName: String {
        let trimmed = androidBaseFileName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "ic_launcher" : trimmed
    }

    private func updateSourceImageSelection(to url: URL) {
        sourceImageURL = url
        outputDirectoryURL = defaultOutputDirectory(for: url)
    }

    private func defaultOutputDirectory(for imageURL: URL) -> URL {
        let directory = imageURL.deletingLastPathComponent()
        let baseName = imageURL.deletingPathExtension().lastPathComponent
        return directory.appendingPathComponent(baseName, isDirectory: true)
    }

    private func handleFileDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }

        provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
            guard let data,
                  let urlString = String(data: data, encoding: .utf8),
                  let url = URL(string: urlString) else {
                return
            }

            DispatchQueue.main.async {
                self.updateSourceImageSelection(to: url)
            }
        }

        return true
    }

    private func chooseImageFile() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "원본 이미지 선택"
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp, .heic]

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        updateSourceImageSelection(to: url)
        return url
    }

    private func chooseOutputFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "출력 폴더 선택"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        return panel.runModal() == .OK ? panel.url : nil
    }
}

private struct PlatformCard<Content: View>: View {
    let title: String
    let symbol: String
    let actionTitle: String
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(title, systemImage: symbol)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
                    .tint(.white)
            }

            content
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.10), Color.white.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }
}

private struct CapsuleTag: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(.white.opacity(0.80))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.08), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
    }
}

private struct WindowConfigurationView: NSViewRepresentable {
    let size: CGSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            configureWindow(from: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configureWindow(from: nsView)
        }
    }

    private func configureWindow(from view: NSView) {
        guard let window = view.window else { return }

        window.setContentSize(size)
        window.contentMinSize = size
        window.contentMaxSize = size
        window.styleMask.remove(.resizable)
        window.center()
    }
}
