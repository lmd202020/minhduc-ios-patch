import SwiftUI
import UIKit

// MARK: - GAME TARGET
enum GameTarget: String, CaseIterable, Identifiable {
    case freeFireTH = "Free Fire TH"
    case freeFireVN = "Free Fire VN"

    var id: String { rawValue }
    var bundleID: String {
        switch self {
        case .freeFireTH: return "com.dts.freefireth"
        case .freeFireVN: return "com.garena.ffvn"
        }
    }
    var schemes: [String] {
        switch self {
        case .freeFireTH: return ["freefireth://"]
        case .freeFireVN: return ["freefirevn://", "freefire://"]
        }
    }
    var imageURL: String { "https://cdn.upanhlaylink.com/i/Hpep960N.png" }
    var accentColor: Color {
        self == .freeFireTH
            ? Color(red: 0.0, green: 0.9, blue: 1.0)
            : Color(red: 1.0, green: 0.2, blue: 0.4)
    }
    var subtitle: String {
        self == .freeFireTH ? "GLOBAL_SERVER // TH" : "VIETNAM_SERVER // VN"
    }
}

// MARK: - PATCH CATEGORY
enum PatchCategory: String, CaseIterable, Identifiable {
    case aimBody = "AimBody"
    case aimLock = "AimLock"
    case aimBot = "AimBot"
    case antiban = "Antiban"
    case nheTam = "Nhẹ Tâm"
    case other = "Khác"

    var id: String { rawValue }
    var displayName: String { rawValue.uppercased() }
    var icon: String {
        switch self {
        case .aimBody: return "figure.walk.motion"
        case .aimLock: return "scope"
        case .aimBot: return "target"
        case .antiban: return "shield.checkerboard"
        case .nheTam: return "battery.100.bolt"
        case .other: return "shippingbox"
        }
    }
    var color: Color {
        switch self {
        case .aimBody: return Color(red: 0.6, green: 0.2, blue: 1.0)
        case .aimLock: return Color(red: 1.0, green: 0.8, blue: 0.0)
        case .aimBot: return Color(red: 1.0, green: 0.35, blue: 0.15)
        case .antiban: return Color(red: 0.2, green: 1.0, blue: 0.4)
        case .nheTam: return Color(red: 0.0, green: 0.9, blue: 1.0)
        case .other: return Color(red: 0.6, green: 0.6, blue: 0.7)
        }
    }
    var detail: String {
        switch self {
        case .aimBody: return "AIMBODY MODULE"
        case .aimLock: return "AIMLOCK MODULE"
        case .aimBot: return "AIMBOT MODULE"
        case .antiban: return "ANTIBAN MODULE"
        case .nheTam: return "NHE TAM MODULE"
        case .other: return "OTHER PATCH FILES"
        }
    }
}

private enum RobotTheme {
    static let bg = Color(red: 0.02, green: 0.03, blue: 0.04)
    static let panel = Color(red: 0.05, green: 0.07, blue: 0.09)
    static let border = Color(red: 0.0, green: 0.9, blue: 1.0).opacity(0.25)
    static let neonCyan = Color(red: 0.0, green: 0.9, blue: 1.0)
    static let neonRed = Color(red: 1.0, green: 0.2, blue: 0.4)
    static let neonGreen = Color(red: 0.2, green: 1.0, blue: 0.4)
    static let textSub = Color(red: 0.0, green: 0.9, blue: 1.0).opacity(0.6)
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

private enum StatusKind {
    case info, success, warning, error
    var color: Color {
        switch self {
        case .info: return RobotTheme.neonCyan
        case .success: return RobotTheme.neonGreen
        case .warning: return .yellow
        case .error: return RobotTheme.neonRed
        }
    }
    var icon: String {
        switch self {
        case .info: return "info.square.fill"
        case .success: return "checkmark.shield.fill"
        case .warning: return "exclamationmark.shield.fill"
        case .error: return "xmark.shield.fill"
        }
    }
}

private struct StatusMessage {
    let text: String
    let kind: StatusKind
}

// MARK: - PATCH TAB VIEW
struct PatchTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var patchStore = PatchProjectStore()

    @State private var selectedGame: GameTarget?
    @State private var selectedCategory: PatchCategory?
    @State private var appliedIDs = Set<UUID>()
    @State private var pendingSwitchStates: [UUID: Bool] = [:]
    @State private var status = StatusMessage(text: "SYS.INIT // READY", kind: .info)
    @State private var showCleaner = false
    @State private var showFiles = false
    @State private var showLogs = false
    @State private var showDisableAllAlert = false
    @State private var logs = ["SYS.INIT // MODULE CONTROLS READY"]

    private var accent: Color { selectedGame?.accentColor ?? RobotTheme.neonCyan }

    private var gameItems: [PatchLibraryItem] {
        guard let game = selectedGame else { return [] }
        return patchStore.items.filter { item in
            item.project?.allBundleIdentifiers.contains(game.bundleID) == true
        }
    }

    private var visibleItems: [PatchLibraryItem] {
        guard let selected = selectedCategory else { return gameItems }
        return gameItems.filter { category(for: $0) == selected }
    }

    private var activeCount: Int { gameItems.filter { pendingSwitchStates[$0.id] ?? appliedIDs.contains($0.id) }.count }

    var body: some View {
        ZStack {
            RobotTheme.bg.ignoresSafeArea()
            CyberGrid()
            VStack(spacing: 0) {
                topHUD
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 18) {
                            Color.clear.frame(height: 1).id("PATCH_TOP")
                            if selectedGame == nil {
                                gameSelectionModule
                            } else if let game = selectedGame, selectedCategory == nil {
                                categorySelectionModule(for: game)
                            } else if let game = selectedGame, let category = selectedCategory {
                                patchListModule(game: game, category: category)
                            }
                            Spacer().frame(height: 24)
                        }
                        .padding(.horizontal, 16)
                    }
                    .onChange(of: selectedGame) { _ in
                        withAnimation(.snappy) { proxy.scrollTo("PATCH_TOP", anchor: .top) }
                    }
                    .onChange(of: selectedCategory) { _ in
                        withAnimation(.snappy) { proxy.scrollTo("PATCH_TOP", anchor: .top) }
                    }
                }
                bottomActionBar
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showCleaner) { CleanerView() }
        .sheet(isPresented: $showLogs) { logsSheet }
        .sheet(isPresented: $showFiles) { filesSheet }
        .alert("TẮT TẤT CẢ MODULE?", isPresented: $showDisableAllAlert) {
            Button("HỦY", role: .cancel) { }
            Button("TẮT HẾT", role: .destructive) { restoreAll() }
        } message: {
            Text("Tắt trạng thái các module của game đã chọn trong ứng dụng.")
        }
        .onAppear {
            patchStore.reload()
            loadSwitchStates()
        }
        .onChange(of: patchStore.items.count) { _ in loadSwitchStates() }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                patchStore.reload()
                loadSwitchStates()
            }
        }
    }

    // MARK: HUD
    private var topHUD: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if let game = selectedGame {
                        AsyncImage(url: URL(string: game.imageURL)) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Color.clear
                            }
                        }
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(accent, lineWidth: 1))
                    } else {
                        Image(systemName: "cpu").foregroundStyle(accent)
                    }
                    Text("PATCH CONTROL // AI")
                        .font(RobotTheme.mono(16, weight: .black))
                        .foregroundStyle(.white)
                }
                Text("SYS.ONLINE :: \(selectedGame?.subtitle ?? "SELECT MODULE")")
                    .font(RobotTheme.mono(10, weight: .bold))
                    .foregroundStyle(RobotTheme.textSub)
            }
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(RobotTheme.neonGreen).frame(width: 8, height: 8)
                Text("READY")
                    .font(RobotTheme.mono(10, weight: .bold))
                    .foregroundStyle(RobotTheme.neonGreen)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RobotTheme.panel)
            .clipShape(CutCornerShape(cut: 6))
            .overlay(CutCornerShape(cut: 6).stroke(RobotTheme.border, lineWidth: 1))
        }
    }

    // MARK: BOTTOM ACTION BAR
    private var bottomActionBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: status.kind.icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(status.kind.color)
                Text(status.text)
                    .font(RobotTheme.mono(10, weight: .bold))
                    .foregroundStyle(status.kind.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer()
                if activeCount > 0 {
                    Text("\(activeCount) ON")
                        .font(RobotTheme.mono(9, weight: .black))
                        .foregroundStyle(RobotTheme.neonGreen)
                }
            }
            .padding(.horizontal, 12)

            HStack(spacing: 10) {
                if selectedGame == nil {
                    infoPill("Chọn game để bắt đầu", icon: "hand.tap.fill")
                } else if selectedCategory == nil {
                    infoPill("Chọn module bên trên", icon: "square.grid.2x2.fill")
                } else if let game = selectedGame {
                    Button { launchGame(game) } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.circle.fill").font(.system(size: 20, weight: .bold))
                            Text("MỞ \(game.rawValue.uppercased())").font(RobotTheme.mono(13, weight: .black))
                        }
                        .foregroundStyle(RobotTheme.bg)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(accent)
                        .clipShape(CutCornerShape(cut: 10))
                    }
                    .buttonStyle(RobotButtonStyle())
                }

                if activeCount > 0 {
                    Button { showDisableAllAlert = true } label: {
                        Image(systemName: "power")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(RobotTheme.neonRed)
                            .frame(width: 50, height: 50)
                            .background(RobotTheme.neonRed.opacity(0.15))
                            .clipShape(CutCornerShape(cut: 10))
                            .overlay(CutCornerShape(cut: 10).stroke(RobotTheme.neonRed, lineWidth: 1))
                    }
                    .buttonStyle(RobotButtonStyle())
                }
            }
            .padding(.horizontal, 12)

            HStack(spacing: 10) {
                toolButton("CLEAN", icon: "trash", color: RobotTheme.neonRed) { showCleaner = true }
                toolButton("FILES", icon: "folder", color: RobotTheme.neonCyan) { showFiles = true }
                toolButton("LOGS", icon: "bell", color: .yellow) { showLogs = true }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .padding(.top, 8)
        .background(RobotTheme.bg.overlay(alignment: .top) {
            Rectangle().fill(RobotTheme.border).frame(height: 1)
        })
    }

    private func infoPill(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(title).font(RobotTheme.mono(12, weight: .bold))
        }
        .foregroundStyle(RobotTheme.textSub)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(RobotTheme.panel)
        .clipShape(CutCornerShape(cut: 10))
        .overlay(CutCornerShape(cut: 10).stroke(RobotTheme.border, lineWidth: 1))
    }

    private func toolButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(color)
                Text(title).font(RobotTheme.mono(10, weight: .bold)).foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(RobotTheme.panel)
            .clipShape(CutCornerShape(cut: 8))
            .overlay(CutCornerShape(cut: 8).stroke(color.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(RobotButtonStyle())
    }

    // MARK: GAME SELECTION
    private var gameSelectionModule: some View {
        VStack(alignment: .leading, spacing: 14) {
            moduleHeader("CHỌN GAME", icon: "target")
            ForEach(GameTarget.allCases) { game in
                Button {
                    withAnimation(.snappy) {
                        selectedGame = game
                        selectedCategory = nil
                    }
                    haptic(.success)
                } label: {
                    gameCard(game)
                }
                .buttonStyle(RobotButtonStyle())
            }
        }
    }

    private func gameCard(_ game: GameTarget) -> some View {
        let count = patchStore.items.filter { $0.project?.allBundleIdentifiers.contains(game.bundleID) == true }.count
        return HStack(spacing: 16) {
            AsyncImage(url: URL(string: game.imageURL)) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Image(systemName: "gamecontroller.fill").foregroundStyle(game.accentColor)
                }
            }
            .frame(width: 68, height: 68)
            .clipShape(CutCornerShape(cut: 12))
            .overlay(CutCornerShape(cut: 12).stroke(game.accentColor, lineWidth: 2))

            VStack(alignment: .leading, spacing: 6) {
                Text(game.rawValue.uppercased()).font(RobotTheme.mono(17, weight: .black)).foregroundStyle(.white)
                Text(game.bundleID).font(RobotTheme.mono(10)).foregroundStyle(RobotTheme.textSub)
                Text("\(count) PATCH PACKAGES")
                    .font(RobotTheme.mono(9, weight: .bold))
                    .foregroundStyle(game.accentColor)
            }
            Spacer()
            Image(systemName: "chevron.right.2").foregroundStyle(game.accentColor)
        }
        .padding(16)
        .frame(minHeight: 100)
        .background(RobotTheme.panel)
        .clipShape(CutCornerShape(cut: 14))
        .overlay(CutCornerShape(cut: 14).stroke(game.accentColor.opacity(0.35), lineWidth: 1))
    }

    // MARK: CATEGORY SELECTION
    private func categorySelectionModule(for game: GameTarget) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            breadcrumbBar(game: game, category: nil)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(categories(for: game)) { category in
                    Button {
                        withAnimation(.snappy) { selectedCategory = category }
                        haptic(.success)
                    } label: {
                        categoryCard(category)
                    }
                    .buttonStyle(RobotButtonStyle())
                }
            }
            if gameItems.isEmpty {
                emptyPackagesMessage
            }
        }
    }

    private func categories(for game: GameTarget) -> [PatchCategory] {
        let available = Set(gameItems.map { category(for: $0) })
        return PatchCategory.allCases.filter { available.contains($0) }
    }

    private func categoryCard(_ category: PatchCategory) -> some View {
        let items = gameItems.filter { self.category(for: $0) == category }
        let isActive = items.contains { pendingSwitchStates[$0.id] ?? appliedIDs.contains($0.id) }
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: category.icon).font(.system(size: 25, weight: .bold)).foregroundStyle(category.color)
                Spacer()
                if isActive { Circle().fill(RobotTheme.neonGreen).frame(width: 9, height: 9) }
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(category.displayName).font(RobotTheme.mono(14, weight: .black)).foregroundStyle(.white)
                Text(category.detail).font(RobotTheme.mono(9)).foregroundStyle(RobotTheme.textSub).lineLimit(1)
            }
            HStack {
                Text("\(items.count) PATCHES").font(RobotTheme.mono(10, weight: .bold)).foregroundStyle(category.color)
                Spacer()
                Image(systemName: "arrow.up.right").foregroundStyle(category.color)
            }
        }
        .padding(15)
        .frame(minHeight: 135)
        .background(isActive ? category.color.opacity(0.08) : RobotTheme.panel)
        .clipShape(CutCornerShape(cut: 12))
        .overlay(CutCornerShape(cut: 12).stroke(category.color.opacity(isActive ? 0.7 : 0.3), lineWidth: isActive ? 2 : 1))
    }

    // MARK: PATCH LIST
    private func patchListModule(game: GameTarget, category: PatchCategory) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            breadcrumbBar(game: game, category: category)
            if visibleItems.isEmpty {
                emptyPackagesMessage
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(visibleItems) { item in
                        patchCard(item)
                    }
                }
            }
        }
    }

    private var emptyPackagesMessage: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray").font(.system(size: 32, weight: .bold)).foregroundStyle(RobotTheme.textSub)
            Text("KHÔNG TÌM THẤY PATCH PACKAGE")
                .font(RobotTheme.mono(12, weight: .bold)).foregroundStyle(RobotTheme.textSub)
            Text("Kiểm tra thư mục Patches trong Copy Bundle Resources và định dạng .3105.")
                .font(RobotTheme.mono(10)).foregroundStyle(RobotTheme.textSub.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(RobotTheme.panel)
        .clipShape(CutCornerShape(cut: 10))
    }

    private func patchCard(_ item: PatchLibraryItem) -> some View {
        let category = self.category(for: item)
        let isApplied = pendingSwitchStates[item.id] ?? appliedIDs.contains(item.id)
        let isPending = pendingSwitchStates[item.id] != nil
        let title = item.project?.name ?? item.packageURL.lastPathComponent
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle().fill(isApplied ? RobotTheme.neonGreen : RobotTheme.textSub).frame(width: 9, height: 9)
                Text(isPending ? "PROCESSING" : (isApplied ? "APPLIED" : (item.isLocked ? "LOCKED" : "READY")))
                    .font(RobotTheme.mono(10, weight: .black))
                    .foregroundStyle(isApplied ? RobotTheme.neonGreen : RobotTheme.textSub)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { pendingSwitchStates[item.id] ?? appliedIDs.contains(item.id) },
                    set: { setPatchApplied($0, item: item) }
                ))
                .labelsHidden()
                .tint(RobotTheme.neonGreen)
                .scaleEffect(0.82)
                
            }
            Text(title)
                .font(RobotTheme.mono(11, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(item.packageURL.lastPathComponent)
                .font(RobotTheme.mono(8))
                .foregroundStyle(RobotTheme.textSub)
                .lineLimit(2)
            if isPending {
                ProgressView().tint(category.color).scaleEffect(0.75).frame(height: 10)
            } else {
                Text(isApplied ? "TAP TO RESTORE" : "TAP TO APPLY")
                    .font(RobotTheme.mono(8, weight: .bold))
                    .foregroundStyle(category.color)
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 125, alignment: .leading)
        .background(isApplied ? category.color.opacity(0.08) : RobotTheme.panel)
        .clipShape(CutCornerShape(cut: 10))
        .overlay(CutCornerShape(cut: 10).stroke(isApplied ? category.color.opacity(0.7) : RobotTheme.border, lineWidth: isApplied ? 2 : 1))
    }

    // MARK: NAVIGATION
    private func breadcrumbBar(game: GameTarget?, category: PatchCategory?) -> some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.snappy) {
                    if selectedCategory != nil { selectedCategory = nil }
                    else { selectedGame = nil }
                }
                haptic(.success)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(RobotTheme.neonCyan)
                    .frame(width: 44, height: 44)
                    .background(RobotTheme.panel)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(RobotTheme.border, lineWidth: 1))
            }
            .buttonStyle(RobotButtonStyle())
            VStack(alignment: .leading, spacing: 2) {
                if let game { Text(game.rawValue.uppercased()).font(RobotTheme.mono(9, weight: .bold)).foregroundStyle(RobotTheme.textSub) }
                Text(category?.displayName ?? "MODULES").font(RobotTheme.mono(15, weight: .black)).foregroundStyle(.white)
            }
            Spacer()
            Text("[ ONLINE ]").font(RobotTheme.mono(9, weight: .bold)).foregroundStyle(RobotTheme.neonGreen)
        }
    }

    private func moduleHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(accent)
            Text(title).font(RobotTheme.mono(14, weight: .black)).foregroundStyle(.white)
            Spacer()
            Text("[ ONLINE ]").font(RobotTheme.mono(9, weight: .bold)).foregroundStyle(RobotTheme.neonGreen)
        }
    }

    // MARK: MODULE STATE (IN-APP ONLY)
    private func category(for item: PatchLibraryItem) -> PatchCategory {
        let name = (item.project?.name ?? item.packageURL.lastPathComponent).lowercased()
        if name.contains("aimbody") || name.contains("body") { return .aimBody }
        if name.contains("aimlock") { return .aimLock }
        if name.contains("aimbot") { return .aimBot }
        if name.contains("antiban") { return .antiban }
        if name.contains("nhẹ tâm") || name.contains("nhe tam") || name.contains("nhetam") { return .nheTam }
        return .other
    }

    private func storageKey(for item: PatchLibraryItem) -> String {
        "module_switch_\(item.packageURL.lastPathComponent)"
    }

    private func setPatchApplied(_ enabled: Bool, item: PatchLibraryItem) {
        // Optimistic UI: update immediately, without disk or network patch operations.
        if enabled { appliedIDs.insert(item.id) }
        else { appliedIDs.remove(item.id) }
        UserDefaults.standard.set(enabled, forKey: storageKey(for: item))
        let title = item.project?.name ?? item.packageURL.lastPathComponent
        setStatus("MODULE \(enabled ? "ON" : "OFF"): \(title)", .success)
        logs.insert("MODULE \(enabled ? "ON" : "OFF") // \(title)", at: 0)
        haptic(.success)
    }

    private func loadSwitchStates() {
        var states = Set<UUID>()
        for item in patchStore.items where UserDefaults.standard.bool(forKey: storageKey(for: item)) {
            states.insert(item.id)
        }
        appliedIDs = states
    }

    private func restoreAll() {
        for item in gameItems {
            appliedIDs.remove(item.id)
            UserDefaults.standard.set(false, forKey: storageKey(for: item))
        }
        setStatus("ALL MODULE SWITCHES OFF", .success)
        logs.insert("MODULE SWITCHES OFF // SELECTED GAME", at: 0)
        haptic(.success)
    }

    private func launchGame(_ game: GameTarget) {
        openScheme(game.schemes, index: 0)
    }

    private func openScheme(_ schemes: [String], index: Int) {
        guard index < schemes.count else {
            setStatus("GAME NOT FOUND / URL SCHEME FAILED", .error)
            return
        }
        guard let url = URL(string: schemes[index]) else {
            openScheme(schemes, index: index + 1)
            return
        }
        UIApplication.shared.open(url, options: [:]) { success in
            DispatchQueue.main.async {
                if success { setStatus("GAME LAUNCH REQUEST SENT", .success) }
                else { openScheme(schemes, index: index + 1) }
            }
        }
    }

    private func setStatus(_ text: String, _ kind: StatusKind) {
        status = StatusMessage(text: text, kind: kind)
    }

    private func haptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    private var logsSheet: some View {
        NavigationStack {
            List {
                ForEach(Array(logs.enumerated()), id: \.offset) { _, entry in
                    Text(entry).font(RobotTheme.mono(12))
                }
            }
            .navigationTitle("SYSTEM LOGS")
            .preferredColorScheme(.dark)
        }
    }

    private var filesSheet: some View {
        NavigationStack {
            List {
                Section("FREE FIRE TH") {
                    ForEach(patchStore.items.filter { $0.project?.allBundleIdentifiers.contains(GameTarget.freeFireTH.bundleID) == true }) { item in
                        Text(item.project?.name ?? item.packageURL.lastPathComponent).font(RobotTheme.mono(11))
                    }
                }
                Section("FREE FIRE VN") {
                    ForEach(patchStore.items.filter { $0.project?.allBundleIdentifiers.contains(GameTarget.freeFireVN.bundleID) == true }) { item in
                        Text(item.project?.name ?? item.packageURL.lastPathComponent).font(RobotTheme.mono(11))
                    }
                }
            }
            .navigationTitle("PATCH LIBRARY")
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: - ROBOT UI COMPONENTS
struct CutCornerShape: Shape {
    var cut: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cut))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cut))
        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cut, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cut))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cut))
        path.closeSubpath()
        return path
    }
}

struct CyberGrid: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let step: CGFloat = 40
                for x in stride(from: 0, to: geo.size.width, by: step) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
                for y in stride(from: 0, to: geo.size.height, by: step) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(RobotTheme.neonCyan.opacity(0.05), lineWidth: 1)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct RobotButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? 0.08 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
