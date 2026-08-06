import SwiftUI
import UniformTypeIdentifiers
import AppKit

@main
struct AppIconGeneratorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 1040, height: 980)
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
    // 자동으로 "추측"만 해서 채운 출력 폴더인지(App Sandbox에서 쓰기 권한이 없음),
    // 사용자가 실제로 패널을 통해 골라서 진짜 쓰기 권한이 생겼는지 구분한다.
    @State private var outputDirectoryIsGranted = false
    @State private var includeIPhone = true
    @State private var includeIPad = true
    @State private var includeMacOS = true
    @State private var includeWatchOS = true
    @State private var includeIOSUniversal = false
    @State private var iOSUniversalDarkURL: URL?
    @State private var iOSUniversalTintedURL: URL?
    @State private var includeAndroid = true
    @State private var includeAppleStoreAssets = false
    @State private var includeAndroidStoreAssets = false
    @State private var androidBaseFileName = "ic_launcher"
    @State private var androidTargetFolder = "mipmap"
    @State private var isGenerating = false
    @State private var isDropTargeted = false
    @State private var activeGuideTopic: GuideTopic?
    @State private var resultRows: [GenerationResultRow] = []
    @State private var resultErrorMessage: String?
    @State private var resultIsSuccess = true
    @State private var showingResultSheet = false
    @State private var aiPrompt = ""
    @State private var isGeneratingAIIcon = false
    @State private var aiErrorMessage: String?
    @State private var showingAPIKeySheet = false
    @State private var geminiAPIKey = ""
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.systemDefault.rawValue

    private var currentAppLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? AppLanguage.systemDefault
    }

    private let androidFolderOptions = ["mipmap", "drawable"]
    private let dropZoneSize: CGFloat = 480

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(alignment: .leading, spacing: 18) {
                headerSection
                aiGenerationSection

                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 18) {
                        dropZone
                        storeAssetsSection
                    }
                    optionsPanel
                }

                hintStrip
            }
            .padding(24)
        }
        .background(WindowConfigurationView(size: CGSize(width: 1040, height: 980)))
        .sheet(item: $activeGuideTopic) { topic in
            GuidePageView(topic: topic)
                .environment(\.locale, currentAppLanguage.locale)
        }
        .sheet(isPresented: $showingResultSheet) {
            ResultSheetView(isSuccess: resultIsSuccess, rows: resultRows, errorMessage: resultErrorMessage)
                .environment(\.locale, currentAppLanguage.locale)
        }
        .sheet(isPresented: $showingAPIKeySheet) {
            APIKeySettingsView(apiKey: geminiAPIKey) { newKey in
                geminiAPIKey = newKey
                KeychainStore.save(newKey)
                showingAPIKeySheet = false
            } onCancel: {
                showingAPIKeySheet = false
            }
            .environment(\.locale, currentAppLanguage.locale)
        }
        .onAppear {
            geminiAPIKey = KeychainStore.load() ?? ""
        }
        .environment(\.locale, currentAppLanguage.locale)
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
                HStack(spacing: 8) {
                    Text("Mac Desktop Tool")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.thinMaterial, in: Capsule())

                    Button {
                        appLanguageRaw = (currentAppLanguage == .korean ? AppLanguage.english : AppLanguage.korean).rawValue
                    } label: {
                        Text(currentAppLanguage.switchToLabel)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help(currentAppLanguage.displayName)
                    .contextMenu {
                        Button("시스템 언어 따르기") {
                            resetLanguageToSystemDefault()
                        }
                    }
                }

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

    private var aiGenerationSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Label("AI로 생성", systemImage: "sparkles")
                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    .fixedSize()

                TextField("예: 로켓 모양의 미니멀한 플랫 아이콘, 파란색 배경", text: $aiPrompt)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isGeneratingAIIcon)
                    .onSubmit { generateAIIcon() }

                Button {
                    generateAIIcon()
                } label: {
                    if isGeneratingAIIcon {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 40)
                    } else {
                        Text("생성")
                            .frame(width: 40)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGeneratingAIIcon || aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    showingAPIKeySheet = true
                } label: {
                    Image(systemName: "key.fill")
                }
                .buttonStyle(.bordered)
                .help("Gemini API 키 설정")
            }

            if let aiErrorMessage {
                Text(aiErrorMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("파일을 올리지 않아도 문장으로 설명하면 아이콘을 자동으로 만들어줍니다. Gemini API 키가 필요합니다 (열쇠 버튼).")
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
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
                        wrappingToggle("iPhone  - 9 different sizes and files", isOn: $includeIPhone)
                        wrappingToggle("iPad  - 10 different sizes and files", isOn: $includeIPad)
                        wrappingToggle("macOS  - 10 different sizes and files", isOn: $includeMacOS)
                        wrappingToggle("watchOS  - 8 different sizes and files", isOn: $includeWatchOS)
                    }
                    .toggleStyle(.checkbox)
                    .font(.system(size: 14.5, weight: .medium))

                    Divider().padding(7)

                    VStack(alignment: .leading, spacing: 4) {
                        wrappingToggle("iOS Universal (Single Size, Xcode 14+)", isOn: $includeIOSUniversal)
                            .toggleStyle(.checkbox)
                            .font(.system(size: 14.5, weight: .medium))

                        wrappingHint("1024x1024 한 장만 생성하고, Xcode가 빌드 시 나머지 사이즈를 자동으로 만듭니다. (Build Settings에서 'Include All App Icon Assets' 필요)")

                        if includeIOSUniversal {
                            VStack(alignment: .leading, spacing: 6) {
                                auxIconRow(
                                    title: "Dark 아이콘",
                                    url: $iOSUniversalDarkURL,
                                    dialogTitle: "iOS 18 Dark 아이콘 원본 선택"
                                )
                                auxIconRow(
                                    title: "Tinted 아이콘",
                                    url: $iOSUniversalTintedURL,
                                    dialogTitle: "iOS 18 Tinted 아이콘 원본 선택"
                                )

                                wrappingHint("iOS 18부터 홈 화면에서 Dark/Tinted 모드로 전환할 수 있어요. 미지정 시 기본(라이트) 아이콘만 생성됩니다. Tinted는 자동으로 흑백 변환되어 저장됩니다.")
                            }
                            .padding(.top, 6)
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

                    wrappingToggle("Android  - 5 densities + adaptive icon", isOn: $includeAndroid)
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

            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Output folder")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Choose") {
                            if let picked = chooseOutputFolder() {
                                outputDirectoryURL = picked
                                outputDirectoryIsGranted = true
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    Text(outputDirectoryURL?.path ?? AppLanguage.localized("Not selected"))
                        .font(.system(size: 12.5))
                        .foregroundStyle(outputDirectoryURL == nil ? .secondary : .primary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    wrappingHint("선택한 폴더 아래에 iPhone/iPad/macOS/watchOS/Android 등 켜져 있는 항목별로 하위 폴더가 자동 생성됩니다. 이미지를 직접 선택하면 원본 파일과 같은 위치에 파일명 폴더로 기본 지정되며, Generate files를 누르면 그 폴더에 대한 쓰기 권한을 한 번 더 확인하는 창이 뜰 수 있습니다.")

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
                .padding(16)
                .background(cardFill)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.85), lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var storeAssetsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Label("스토어 등록 이미지", systemImage: "photo.on.rectangle.angled")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))

                HStack(alignment: .top, spacing: 24) {
                    wrappingToggle("Apple  - macOS/iPhone/iPad 스크린샷 placeholder", isOn: $includeAppleStoreAssets)
                        .toggleStyle(.checkbox)
                        .font(.system(size: 14.5, weight: .medium))

                    wrappingToggle("Android  - Play Store feature graphic + 스크린샷 placeholder", isOn: $includeAndroidStoreAssets)
                        .toggleStyle(.checkbox)
                        .font(.system(size: 14.5, weight: .medium))
                }

                wrappingHint("실제 스크린샷은 아니지만, 원본 이미지를 흰 배경 중앙에 배치해 App Store Connect / Play Console에 필요한 사이즈로 만듭니다. 파일명에 용도와 사이즈가 표기되어 있어 바로 구분할 수 있습니다.")
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardFill)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.85), lineWidth: 1)
            )
        }
        .frame(width: dropZoneSize)
    }

    private func auxIconRow(title: String, url: Binding<URL?>, dialogTitle: String) -> some View {
        HStack(spacing: 8) {
            Text(LocalizedStringKey(title))
                .font(.system(size: 12.5))
                .foregroundStyle(.secondary)
                .frame(width: 78, alignment: .leading)

            Text(url.wrappedValue?.lastPathComponent ?? AppLanguage.localized("미지정 (라이트 아이콘 사용)"))
                .font(.system(size: 11.5))
                .foregroundStyle(url.wrappedValue == nil ? .secondary : .primary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 8)

            Button("선택") {
                if let picked = chooseAuxIconFile(title: dialogTitle) {
                    url.wrappedValue = picked
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            if url.wrappedValue != nil {
                Button("지우기") {
                    url.wrappedValue = nil
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
            }
        }
    }

    private func chooseAuxIconFile(title: String) -> URL? {
        let panel = NSOpenPanel()
        panel.title = AppLanguage.localized(forKey: title)
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp, .heic]

        return panel.runModal() == .OK ? panel.url : nil
    }

    private func wrappingToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(LocalizedStringKey(title))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func wrappingHint(_ text: String) -> some View {
        Text(LocalizedStringKey(text))
            .font(.system(size: 11.5))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cardFill: some ShapeStyle {
        .linearGradient(
            colors: [Color.white.opacity(0.9), Color.white.opacity(0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var canGenerate: Bool {
        !isGenerating && sourceImageURL != nil && outputDirectoryURL != nil
            && (includeIPhone || includeIPad || includeMacOS || includeWatchOS || includeIOSUniversal || includeAndroid
                || includeAppleStoreAssets || includeAndroidStoreAssets)
    }

    private func generateIcons() {
        guard let sourceImageURL else {
            return
        }

        // 출력 폴더가 "추측"으로만 채워져 있고 사용자가 실제 패널로 승인한 적이 없으면,
        // App Sandbox 아래에서는 그 폴더에 하위 폴더/파일을 쓸 권한이 아예 없다.
        // 여기서 같은 위치를 미리 채워둔 패널을 한 번 더 띄워 진짜 승인을 받는다.
        if !outputDirectoryIsGranted {
            guard let confirmed = chooseOutputFolder() else {
                return
            }
            outputDirectoryURL = confirmed
            outputDirectoryIsGranted = true
        }

        guard let outputDirectoryURL else {
            return
        }

        isGenerating = true
        defer { isGenerating = false }

        // NSOpenPanel로 받은 보안 스코프 URL은 패널이 닫힌 직후 짧은 구간에서만
        // 암묵적으로 접근이 허용될 수 있다. 명시적으로 접근을 다시 시작해서
        // App Sandbox 아래에서 하위 폴더 생성/파일 쓰기가 거부되지 않게 한다.
        let sourceAccessStarted = sourceImageURL.startAccessingSecurityScopedResource()
        let outputAccessStarted = outputDirectoryURL.startAccessingSecurityScopedResource()
        defer {
            if sourceAccessStarted {
                sourceImageURL.stopAccessingSecurityScopedResource()
            }
            if outputAccessStarted {
                outputDirectoryURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let generator = IconGenerator()
            var result = try generator.generate(
                sourceURL: sourceImageURL,
                outputDirectory: outputDirectoryURL,
                includeIPhone: includeIPhone,
                includeIPad: includeIPad,
                includeMacOS: includeMacOS,
                includeWatchOS: includeWatchOS,
                includeIOSUniversal: includeIOSUniversal,
                iOSUniversalDarkURL: iOSUniversalDarkURL,
                iOSUniversalTintedURL: iOSUniversalTintedURL,
                includeAndroid: includeAndroid,
                androidBaseFileName: sanitizedAndroidBaseName,
                androidTargetRoot: androidTargetFolder
            )

            let storeAssetGenerator = StoreAssetGenerator()
            result += try storeAssetGenerator.generate(
                sourceURL: sourceImageURL,
                outputDirectory: outputDirectoryURL,
                includeAppleStoreAssets: includeAppleStoreAssets,
                includeAndroidStoreAssets: includeAndroidStoreAssets
            )

            resultIsSuccess = true
            resultRows = GenerationResultRow.from(result)
            resultErrorMessage = nil
            showingResultSheet = true
        } catch {
            resultIsSuccess = false
            resultRows = []
            resultErrorMessage = error.localizedDescription
            showingResultSheet = true
        }
    }

    private var sanitizedAndroidBaseName: String {
        let trimmed = androidBaseFileName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "ic_launcher" : trimmed
    }

    private func updateSourceImageSelection(to url: URL) {
        sourceImageURL = url
        outputDirectoryURL = defaultOutputDirectory(for: url)
        // 이미지 파일명 옆에 있으리라 "추측"만 한 경로일 뿐, 사용자가 패널로 승인한 폴더가
        // 아니므로 App Sandbox에서는 쓰기 권한이 없다. "Generate files" 시점에 실제 패널로
        // 한 번 더 확인받는다.
        outputDirectoryIsGranted = false
    }

    private func generateAIIcon() {
        let trimmedPrompt = aiPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty, !isGeneratingAIIcon else { return }

        guard !geminiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            aiErrorMessage = AppLanguage.localized("Gemini API 키가 설정되지 않았습니다. 열쇠 아이콘을 눌러 먼저 설정하세요.")
            showingAPIKeySheet = true
            return
        }

        isGeneratingAIIcon = true
        aiErrorMessage = nil

        Task {
            do {
                let service = GeminiIconService()
                let tempURL = try await service.generateIconSourceFile(prompt: trimmedPrompt, apiKey: geminiAPIKey)
                await MainActor.run {
                    handleAIGeneratedIcon(at: tempURL)
                    isGeneratingAIIcon = false
                }
            } catch {
                await MainActor.run {
                    aiErrorMessage = error.localizedDescription
                    isGeneratingAIIcon = false
                }
            }
        }
    }

    private func resetLanguageToSystemDefault() {
        UserDefaults.standard.removeObject(forKey: AppLanguage.storageKey)
        appLanguageRaw = AppLanguage.systemDefault.rawValue
    }

    private func handleAIGeneratedIcon(at url: URL) {
        sourceImageURL = url

        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        outputDirectoryURL = downloads.appendingPathComponent("AppIcon", isDirectory: true)
        // ~/Downloads 하위는 com.apple.security.files.downloads.read-write entitlement로
        // 패널 없이도 쓰기가 허용되므로, 다른 자동 제안 경로와 달리 바로 승인된 것으로 취급한다.
        outputDirectoryIsGranted = true
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
        panel.title = AppLanguage.localized("원본 이미지 선택")
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
        panel.title = AppLanguage.localized("출력 폴더 선택")
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        // 자동 제안된 경로가 있으면 패널이 그 위치에서 바로 시작하도록 한다.
        // (App Sandbox 승인용 재확인 패널일 때 클릭 한 번으로 끝나게 하기 위함)
        if let outputDirectoryURL {
            panel.directoryURL = outputDirectoryURL.deletingLastPathComponent()
            panel.nameFieldStringValue = outputDirectoryURL.lastPathComponent
        }

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
