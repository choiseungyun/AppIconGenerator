import SwiftUI
import UniformTypeIdentifiers
import AppKit

@main
struct AppIconGeneratorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 940, height: 780)
        }
        .windowResizability(.contentSize)
    }
}

struct ContentView: View {
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
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingResultAlert = false

    private let androidFolderOptions = ["mipmap", "drawable"]
    private let dropZoneSize: CGFloat = 520

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(alignment: .leading, spacing: 18) {
                headerSection

                HStack(alignment: .top, spacing: 18) {
                    dropZone
                    optionsPanel
                }

                hintStrip
            }
            .padding(24)
        }
        .background(WindowConfigurationView(size: CGSize(width: 940, height: 780)))
        .sheet(item: $activeGuideTopic) { topic in
            GuidePageView(topic: topic)
        }
        .alert(alertTitle, isPresented: $showingResultAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.97, blue: 1.0),
                    Color(red: 0.91, green: 0.95, blue: 0.99),
                    Color(red: 0.98, green: 0.98, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: 240, style: .continuous)
                .fill(Color.blue.opacity(0.08))
                .frame(width: 430, height: 430)
                .blur(radius: 8)
                .offset(x: -300, y: -260)

            RoundedRectangle(cornerRadius: 260, style: .continuous)
                .fill(Color.cyan.opacity(0.10))
                .frame(width: 500, height: 500)
                .blur(radius: 14)
                .offset(x: 380, y: 260)
        }
        .ignoresSafeArea()
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("App Icon Generator")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text("원본 이미지를 넣으면 iOS, Android, macOS, watchOS용 아이콘 세트를 한 번에 생성합니다.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text("Mac Desktop Tool")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: Capsule())

                Text("Drag, preview, generate")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 6)
    }

    private var hintStrip: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(.blue)
            Text("1024x1024 정사각형 이미지를 추천합니다. 이미지 선택 시 기본 output folder는 파일명 폴더로 자동 설정됩니다.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.9), lineWidth: 1)
        )
    }

    private var dropZone: some View {
        Button {
            sourceImageURL = chooseImageFile()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.92), Color.white.opacity(0.78)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.9), lineWidth: 1)

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [9]))
                    .foregroundStyle(isDropTargeted ? Color.accentColor : Color.gray.opacity(0.35))

                if let previewImage = previewImage {
                    Image(nsImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(34)
                        .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 10)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo")
                            .font(.system(size: 74, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Click or drag image file")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("1024 x 1024")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.85), in: Capsule())

                        if let sourceImageURL {
                            Text(sourceImageURL.lastPathComponent)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 360)
            .frame(width: dropZoneSize, height: dropZoneSize)
            .compositingGroup()
            .shadow(color: .black.opacity(0.08), radius: 28, x: 0, y: 14)
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
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Apple targets", systemImage: "apple.logo")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))

                        Spacer()

                        Button("iOS 가이드 보기") {
                            activeGuideTopic = .ios
                        }
                        .buttonStyle(.bordered)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("iPhone  - 11 different sizes and files", isOn: $includeIPhone)
                        Toggle("iPad  - 13 different sizes and files", isOn: $includeIPad)
                        Toggle("macOS  - 11 different sizes and files", isOn: $includeMacOS)
                        Toggle("watchOS  - 8 different sizes and files", isOn: $includeWatchOS)
                    }
                    .toggleStyle(.checkbox)
                    .font(.system(size: 14.5, weight: .medium))
                }
                .padding(16)
                .background(cardFill)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.85), lineWidth: 1)
                )
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Android", systemImage: "square.stack.3d.up")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))

                        Spacer()

                        Button("Android 가이드 보기") {
                            activeGuideTopic = .android
                        }
                        .buttonStyle(.bordered)
                    }

                    Toggle("Android  - 4 different sizes and files", isOn: $includeAndroid)
                        .toggleStyle(.checkbox)
                        .font(.system(size: 14.5, weight: .medium))

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Text("File name")
                                .foregroundStyle(.secondary)
                                .frame(width: 84, alignment: .leading)
                            TextField("ic_launcher", text: $androidBaseFileName)
                                .textFieldStyle(.roundedBorder)
                                .disabled(!includeAndroid)
                        }

                        HStack(spacing: 10) {
                            Text("Target folders")
                                .foregroundStyle(.secondary)
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
                .padding(16)
                .background(cardFill)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.85), lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Output folder")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Choose") {
                        outputDirectoryURL = chooseOutputFolder()
                    }
                    .buttonStyle(.bordered)
                }

                Text(outputDirectoryURL?.path ?? "Not selected")
                    .font(.system(size: 12.5))
                    .foregroundStyle(outputDirectoryURL == nil ? .secondary : .primary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            }
        }
        .frame(width: 360)
    }

    private var cardFill: some ShapeStyle {
        .linearGradient(
            colors: [Color.white.opacity(0.9), Color.white.opacity(0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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

            alertTitle = "생성 성공"
            alertMessage = result.joined(separator: "\n")
            if alertMessage.isEmpty {
                alertMessage = "아이콘 생성이 완료되었습니다."
            }
            showingResultAlert = true
        } catch {
            alertTitle = "생성 실패"
            alertMessage = error.localizedDescription
            showingResultAlert = true
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
