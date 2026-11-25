import SwiftUI
import UIKit
import CryptoKit
import Combine

// MARK: - GAME TARGET
enum GameTarget: String, CaseIterable, Identifiable {
    case freeFireTH = "Free Fire TH"
    case freeFireVN = "Free Fire VN"

    var id: String { rawValue }

    var imageURL: String {
        switch self {
        case .freeFireTH: return "https://cdn.upanhlaylink.com/i/Hpep960N.png"
        case .freeFireVN: return "https://cdn.upanhlaylink.com/i/Hpep960N.png"
        }
    }

    var bundleID: String {
        switch self {
        case .freeFireTH: return "com.dts.freefireth"
        case .freeFireVN: return "com.garena.ffvn"
        }
    }

    var urlScheme: String {
        switch self {
        case .freeFireTH: return "freefireth://"
        case .freeFireVN: return "freefirevn://"
        }
    }

    var fallbackSchemes: [String] {
        switch self {
        case .freeFireTH: return ["freefireth://"]
        case .freeFireVN: return ["freefirevn://", "freefire://"]
        }
    }

    var accentColor: Color {
        switch self {
        case .freeFireTH: return Color(red: 0.0, green: 0.9, blue: 1.0)
        case .freeFireVN: return Color(red: 1.0, green: 0.2, blue: 0.4)
        }
    }

    var subtitle: String {
        switch self {
        case .freeFireTH: return "GLOBAL_SERVER // ROOT"
        case .freeFireVN: return "VIETNAM_SERVER // LOCAL"
        }
    }

    var friendlyName: String {
        switch self {
        case .freeFireTH: return "Free Fire TH"
        case .freeFireVN: return "Free Fire VN"
        }
    }
}

// MARK: - PATCH CATEGORY
enum PatchCategory: String, CaseIterable, Identifiable {
    case aimBody = "AimBody"
    case aimLock = "AimLock"
    case aimBot  = "AimBot"
    case antiban = "Antiban"
    case nheTam  = "Nhẹ Tâm"
    case other   = "Khác"

    var id: String { rawValue }
    var displayName: String { rawValue.uppercased() }

    var icon: String {
        switch self {
        case .aimBody: return "figure.walk.motion"
        case .aimLock: return "scope"
        case .aimBot:  return "target"
        case .antiban: return "shield.checkerboard"
        case .nheTam:  return "battery.100.bolt"
        case .other:   return "shippingbox"
        }
    }

    var color: Color {
        switch self {
        case .aimBody: return Color(red: 0.6, green: 0.2, blue: 1.0)
        case .aimLock: return Color(red: 1.0, green: 0.8, blue: 0.0)
        case .aimBot:  return Color(red: 1.0, green: 0.35, blue: 0.15)
        case .antiban: return Color(red: 0.2, green: 1.0, blue: 0.4)
        case .nheTam:  return Color(red: 0.0, green: 0.9, blue: 1.0)
        case .other:   return Color(red: 0.6, green: 0.6, blue: 0.7)
        }
    }

    var description: String {
        switch self {
        case .aimBody: return "HITBOX_TRACK: ACTIVE"
        case .aimLock: return "TARGET_LOCK: ENABLED"
        case .aimBot:  return "AIM TRAINING: MODULE"
        case .antiban: return "FIREWALL: STEALTH"
        case .nheTam:  return "OVERCLOCK_MEM: LOW"
        case .other:   return "UNCLASSIFIED FILES"
        }
    }
}

// MARK: - THEME
private enum RobotTheme {
    static let bg        = Color(red: 0.02, green: 0.03, blue: 0.04)
    static let panel     = Color(red: 0.05, green: 0.07, blue: 0.09)
    static let panelHi   = Color(red: 0.08, green: 0.11, blue: 0.14)
    static let border    = Color(red: 0.0, green: 0.9, blue: 1.0).opacity(0.25)
    static let neonCyan  = Color(red: 0.0, green: 0.9, blue: 1.0)
    static let neonRed   = Color(red: 1.0, green: 0.2, blue: 0.4)
    static let neonGreen = Color(red: 0.2, green: 1.0, blue: 0.4)
    static let textSub   = Color(red: 0.0, green: 0.9, blue: 1.0).opacity(0.6)

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - STATUS
private enum StatusKind {
    case info, success, warning, error
    var color: Color {
        switch self {
        case .info:    return RobotTheme.neonCyan
        case .success: return RobotTheme.neonGreen
        case .warning: return Color.yellow
        case .error:   return RobotTheme.neonRed
        }
    }
    var icon: String {
        switch self {
        case .info:    return "info.square.fill"
        case .success: return "checkmark.shield.fill"
        case .warning: return "exclamationmark.shield.fill"
        case .error:   return "xmark.shield.fill"
        }
    }
}

private struct StatusMessage {
    let text: String
    let kind: StatusKind
    var date = Date()
}

// MARK: - MAIN VIEW
struct PatchTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var patchStore = PatchProjectStore()

    @State private var selectedGame: GameTarget? = nil
    @State private var selectedCategory: PatchCategory? = nil

    @State private var patchOperationBusy = false
    @State private var status = StatusMessage(text: "SYS.INIT // READY", kind: .info)
    @State private var showCleaner = false
    @State private var showDisableAllAlert = false
    @State private var patchStates: [String: Bool] = [:]

    @State private var showExplorer = false
    @State private var notifications: [String] = ["SYS.INIT // BOOT SEQUENCE COMPLETE"]
    @State private var showNotifications = false

    private var accent: Color { selectedGame?.accentColor ?? RobotTheme.neonCyan }

    // MARK: - DATA
    private var sortedItems: [PatchLibraryItem] {
        patchStore.items.sorted {
            $0.packageURL.lastPathComponent < $1.packageURL.lastPathComponent
        }
    }

    private var filteredItemsForGame: [PatchLibraryItem] {
        guard let game = selectedGame else { return [] }
        return sortedItems.filter { item in
            let name = item.packageURL.lastPathComponent.lowercased()
            switch game {
            case .freeFireTH:
                return name.contains("(20)") || name.contains("(21)") ||
                       name.contains("(22)") || name.contains("(23)") ||
                       name.contains("(24)")
            case .freeFireVN:
                let keys = ["aimbody", "aimlock", "aimbot", "antiban", "nhetam"]
                return keys.contains { name.contains($0) }
            }
        }
    }

    private var filteredItems: [PatchLibraryItem] {
        guard let category = selectedCategory else { return filteredItemsForGame }
        return filteredItemsForGame.filter { categorizeItem($0) == category }
    }

    private var activeCount: Int {
        filteredItems.filter { patchStates[$0.packageURL.lastPathComponent] ?? false }.count
    }

    private var activeCountAll: Int {
        filteredItemsForGame.filter { patchStates[$0.packageURL.lastPathComponent] ?? false }.count
    }

    // MARK: - BODY
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
                            Color.clear.frame(height: 1).id("TOP")

                            if selectedGame == nil {
                                gameSelectionModule
                            } else if let game = selectedGame, selectedCategory == nil {
                                categorySelectionModule(for: game)
                            } else if let game = selectedGame, let cat = selectedCategory {
                                patchListModule(game: game, category: cat)
                            }

                            Spacer().frame(height: 100)
                        }
                        .padding(.horizontal, 16)
                    }
                    .onChange(of: selectedGame) { _ in
                        withAnimation(.snappy) { proxy.scrollTo("TOP", anchor: .top) }
                    }
                    .onChange(of: selectedCategory) { _ in
                        withAnimation(.snappy) { proxy.scrollTo("TOP", anchor: .top) }
                    }
                }

                bottomActionBar
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showCleaner) { CleanerView() }
        .sheet(isPresented: $showNotifications) { notificationSheet }
        .sheet(isPresented: $showExplorer) { explorerSheet }
        .alert("TẮT TẤT CẢ PATCH?", isPresented: $showDisableAllAlert) {
            Button("HỦY", role: .cancel) {}
            Button("TẮT HẾT", role: .destructive) { disableAll() }
        } message: {
            Text("Toàn bộ patch đang bật sẽ được khôi phục về trạng thái gốc.")
        }
        .onAppear { prepareAndLoadPatches() }
        .onChange(of: scenePhase) { phase in
            if phase == .active, !patchOperationBusy { syncPatchStates() }
        }
    }

    // MARK: - TOP HUD
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
                Circle()
                    .fill(patchOperationBusy ? Color.yellow : RobotTheme.neonGreen)
                    .frame(width: 8, height: 8)
                Text(patchOperationBusy ? "BUSY" : "READY")
                    .font(RobotTheme.mono(10, weight: .bold))
                    .foregroundStyle(patchOperationBusy ? .yellow : RobotTheme.neonGreen)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RobotTheme.panel)
            .clipShape(CutCornerShape(cut: 6))
            .overlay(CutCornerShape(cut: 6).stroke(RobotTheme.border, lineWidth: 1))
        }
    }

    // MARK: - BOTTOM ACTION BAR
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
                    .minimumScaleFactor(0.8)
                Spacer()
                if activeCountAll > 0 {
                    Text("\(activeCountAll) ON")
                        .font(RobotTheme.mono(9, weight: .black))
                        .foregroundStyle(RobotTheme.neonGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RobotTheme.neonGreen.opacity(0.15))
                        .clipShape(CutCornerShape(cut: 4))
                }
            }
            .padding(.horizontal, 12)

            HStack(spacing: 10) {
                if selectedGame == nil {
                    infoPill(text: "Chọn game để bắt đầu", icon: "hand.tap.fill")
                } else if selectedCategory == nil {
                    infoPill(text: "Chọn module bên trên", icon: "square.grid.2x2.fill")
                } else if let game = selectedGame {
                    Button {
                        launchGame(game)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text("MỞ \(game.friendlyName.uppercased())")
                                .font(RobotTheme.mono(14, weight: .black))
                        }
                        .foregroundStyle(RobotTheme.bg)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(accent)
                        .clipShape(CutCornerShape(cut: 10))
                        .shadow(color: accent.opacity(0.4), radius: 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(RobotButtonStyle())
                }

                if activeCountAll > 0 {
                    Button { showDisableAllAlert = true } label: {
                        Image(systemName: "power")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(RobotTheme.neonRed)
                            .frame(width: 52, height: 52)
                            .background(RobotTheme.neonRed.opacity(0.15))
                            .clipShape(CutCornerShape(cut: 10))
                            .overlay(
                                CutCornerShape(cut: 10)
                                    .stroke(RobotTheme.neonRed, lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(RobotButtonStyle())
                }
            }
            .padding(.horizontal, 12)

            HStack(spacing: 10) {
                toolButton(title: "CLEAN",    icon: "trash",  color: RobotTheme.neonRed)   { showCleaner = true }
                toolButton(title: "FILES",    icon: "folder", color: RobotTheme.neonCyan)  { showExplorer = true }
                toolButton(title: "LOGS",     icon: "bell",   color: Color.yellow)         { showNotifications = true }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .padding(.top, 8)
        .background(
            RobotTheme.bg
                .overlay(
                    Rectangle()
                        .fill(RobotTheme.border)
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }

    private func infoPill(text: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
                .font(RobotTheme.mono(12, weight: .bold))
        }
        .foregroundStyle(RobotTheme.textSub)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(RobotTheme.panel)
        .clipShape(CutCornerShape(cut: 10))
        .overlay(
            CutCornerShape(cut: 10).stroke(RobotTheme.border, lineWidth: 1)
        )
    }

    private func toolButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(RobotTheme.mono(10, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(RobotTheme.panel)
            .clipShape(CutCornerShape(cut: 8))
            .overlay(CutCornerShape(cut: 8).stroke(color.opacity(0.3), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(RobotButtonStyle())
    }

    // MARK: - GAME SELECTION
    private var gameSelectionModule: some View {
        VStack(alignment: .leading, spacing: 14) {
            moduleHeader(title: "CHỌN GAME", icon: "target")

            ForEach(GameTarget.allCases) { game in
                Button {
                    withAnimation(.snappy) {
                        selectedGame = game
                        selectedCategory = nil
                    }
                    haptic(.success)
                } label: {
                    robotGameCard(game)
                }
                .buttonStyle(RobotButtonStyle())
            }
        }
    }

    private func robotGameCard(_ game: GameTarget) -> some View {
        let isSelected = selectedGame == game
        return HStack(spacing: 16) {
            AsyncImage(url: URL(string: game.imageURL)) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else if phase.error != nil {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.red)
                        .background(Color.red.opacity(0.1))
                } else {
                    ProgressView()
                        .tint(game.accentColor)
                        .background(Color.white.opacity(0.05))
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(CutCornerShape(cut: 12))
            .overlay(
                CutCornerShape(cut: 12)
                    .stroke(game.accentColor, lineWidth: isSelected ? 3 : 2)
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(game.rawValue.uppercased())
                    .font(RobotTheme.mono(18, weight: .black))
                    .foregroundStyle(.white)
                Text(game.bundleID)
                    .font(RobotTheme.mono(11))
                    .foregroundStyle(RobotTheme.textSub)
                if isSelected {
                    Label("ĐÃ CHỌN", systemImage: "checkmark.circle.fill")
                        .font(RobotTheme.mono(10, weight: .bold))
                        .foregroundStyle(RobotTheme.neonGreen)
                }
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right.2")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(isSelected ? RobotTheme.neonGreen : game.accentColor)
        }
        .padding(18)
        .frame(minHeight: 108)
        .background(isSelected ? game.accentColor.opacity(0.12) : RobotTheme.panel)
        .clipShape(CutCornerShape(cut: 14))
        .overlay(
            CutCornerShape(cut: 14)
                .stroke(
                    isSelected ? game.accentColor : game.accentColor.opacity(0.3),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(color: isSelected ? game.accentColor.opacity(0.35) : .clear, radius: 12)
        .contentShape(Rectangle())
    }

    // MARK: - CATEGORY SELECTION
    private func categorySelectionModule(for game: GameTarget) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            breadcrumbBar(game: game, category: nil)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12),
                          GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(categoriesForGame(game)) { category in
                    Button {
                        withAnimation(.snappy) { selectedCategory = category }
                        haptic(.success)
                    } label: {
                        robotCategoryCard(category, game: game)
                    }
                    .buttonStyle(RobotButtonStyle())
                }
            }
        }
    }

    private func categoriesForGame(_ game: GameTarget) -> [PatchCategory] {
        var result: [PatchCategory] = []
        for cat in PatchCategory.allCases where cat != .other {
            let has = filteredItemsForGame.contains { categorizeItem($0) == cat }
            if has { result.append(cat) }
        }
        let hasOther = filteredItemsForGame.contains { categorizeItem($0) == .other }
        if hasOther { result.append(.other) }
        
        if result.isEmpty {
            result = PatchCategory.allCases.filter { $0 != .other }
        }
        return result
    }

    private func robotCategoryCard(_ category: PatchCategory, game: GameTarget) -> some View {
        let count = filteredItemsForGame.filter { categorizeItem($0) == category }.count
        let isActive = filteredItemsForGame.contains {
            categorizeItem($0) == category &&
            (patchStates[$0.packageURL.lastPathComponent] ?? false)
        }

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: category.icon)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(category.color)
                Spacer()
                if isActive {
                    Circle().fill(RobotTheme.neonGreen)
                        .frame(width: 10, height: 10)
                        .shadow(color: RobotTheme.neonGreen, radius: 4)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(category.displayName)
                    .font(RobotTheme.mono(15, weight: .black))
                    .foregroundStyle(.white)
                Text(category.description)
                    .font(RobotTheme.mono(9))
                    .foregroundStyle(RobotTheme.textSub)
                    .lineLimit(1)
            }

            HStack {
                Text("\(count) FILES")
                    .font(RobotTheme.mono(11, weight: .bold))
                    .foregroundStyle(count > 0 ? category.color : RobotTheme.textSub)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(category.color.opacity(0.7))
            }
        }
        .padding(16)
        .frame(minHeight: 140)
        .background(isActive ? category.color.opacity(0.08) : RobotTheme.panel)
        .clipShape(CutCornerShape(cut: 12))
        .overlay(
            CutCornerShape(cut: 12)
                .stroke(
                    isActive ? category.color.opacity(0.7) : category.color.opacity(0.3),
                    lineWidth: isActive ? 2 : 1
                )
        )
        .contentShape(Rectangle())
    }

    // MARK: - PATCH LIST
    private func patchListModule(game: GameTarget, category: PatchCategory) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            breadcrumbBar(game: game, category: category)

            if category == .aimBot {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("AimBot: bật/tắt bình thường. Trạng thái có thể chưa xác minh.")
                        .font(RobotTheme.mono(9, weight: .bold))
                        .foregroundStyle(.yellow)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(0.08))
                .clipShape(CutCornerShape(cut: 8))
                .overlay(CutCornerShape(cut: 8).stroke(Color.yellow.opacity(0.3), lineWidth: 1))
            }

            if filteredItems.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(RobotTheme.textSub)
                    Text("KHÔNG CÓ PATCH NÀO")
                        .font(RobotTheme.mono(12, weight: .bold))
                        .foregroundStyle(RobotTheme.textSub)
                    Text("Hãy import file patch cho \(category.displayName)")
                        .font(RobotTheme.mono(10))
                        .foregroundStyle(RobotTheme.textSub.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(30)
                .background(RobotTheme.panel)
                .clipShape(CutCornerShape(cut: 10))
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12),
                              GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(filteredItems, id: \.id) { item in
                        robotPatchCard(item, category: category)
                    }
                }
            }
        }
    }

    private func robotPatchCard(_ item: PatchLibraryItem, category: PatchCategory) -> some View {
        let filename = item.packageURL.lastPathComponent
        let enabled  = patchStates[filename] ?? false
        let isBusy   = patchOperationBusy

        return Button {
            guard !isBusy else { return }
            togglePatch(packageFilename: filename)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Circle()
                        .fill(enabled ? RobotTheme.neonGreen : RobotTheme.textSub)
                        .frame(width: 10, height: 10)
                    Text(enabled ? "ACTIVE" : "OFF")
                        .font(RobotTheme.mono(10, weight: .black))
                        .foregroundStyle(enabled ? RobotTheme.neonGreen : RobotTheme.textSub)
                    Spacer()
                    ZStack {
                        Capsule()
                            .fill(enabled
                                  ? RobotTheme.neonGreen.opacity(0.25)
                                  : Color.white.opacity(0.08))
                            .frame(width: 42, height: 24)
                        Circle()
                            .fill(enabled ? RobotTheme.neonGreen : Color.gray)
                            .frame(width: 18, height: 18)
                            .offset(x: enabled ? 9 : -9)
                            .animation(.easeInOut(duration: 0.18), value: enabled)
                    }
                }

                Text(filename)
                    .font(RobotTheme.mono(11, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.leading)

                if isBusy {
                    ProgressView()
                        .tint(category.color)
                        .scaleEffect(0.7)
                        .frame(height: 12)
                }
            }
            .padding(14)
            .frame(minHeight: 110)
            .background(enabled ? category.color.opacity(0.08) : RobotTheme.panel)
            .clipShape(CutCornerShape(cut: 10))
            .overlay(
                CutCornerShape(cut: 10)
                    .stroke(
                        enabled ? category.color.opacity(0.6) : RobotTheme.border,
                        lineWidth: enabled ? 2 : 1
                    )
            )
            .contentShape(Rectangle())
            .opacity(isBusy ? 0.6 : 1)
        }
        .buttonStyle(RobotButtonStyle())
        .disabled(isBusy)
    }

    // MARK: - BREADCRUMB
    private func breadcrumbBar(game: GameTarget?, category: PatchCategory?) -> some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.snappy) {
                    if selectedCategory != nil {
                        selectedCategory = nil
                    } else {
                        selectedGame = nil
                    }
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
                if let game = game {
                    Text(game.rawValue.uppercased())
                        .font(RobotTheme.mono(9, weight: .bold))
                        .foregroundStyle(RobotTheme.textSub)
                }
                Text(category?.displayName ?? "MODULES")
                    .font(RobotTheme.mono(15, weight: .black))
                    .foregroundStyle(.white)
            }
            Spacer()
            Text("[ ONLINE ]")
                .font(RobotTheme.mono(9, weight: .bold))
                .foregroundStyle(RobotTheme.neonGreen)
        }
    }

    private func moduleHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(accent)
            Text(title)
                .font(RobotTheme.mono(14, weight: .black))
                .foregroundStyle(.white)
            Spacer()
            Text("[ ONLINE ]")
                .font(RobotTheme.mono(9, weight: .bold))
                .foregroundStyle(RobotTheme.neonGreen)
        }
    }

    // MARK: - CORE LOGIC
    private func categorizeItem(_ item: PatchLibraryItem) -> PatchCategory {
        let name = item.packageURL.lastPathComponent.lowercased()

        if selectedGame == .freeFireTH {
            if let start = name.firstIndex(of: "("),
               let end   = name.firstIndex(of: ")") {
                let key = String(name[name.index(after: start)..<end])
                switch key {
                case "20": return .aimBody
                case "21": return .aimLock
                case "22": return .antiban
                case "23": return .nheTam
                case "24": return .aimBot
                default:   break
                }
            }
        }

        if name.contains("aimbody") { return .aimBody }
        if name.contains("aimlock") { return .aimLock }
        if name.contains("aimbot")  { return .aimBot }
        if name.contains("antiban") { return .antiban }
        if name.contains("nhetam")  { return .nheTam }

        return .other
    }

    private func launchGame(_ game: GameTarget) {
        switch game {
        case .freeFireTH:
            guard let url = URL(string: "freefireth://") else { return }
            UIApplication.shared.open(url, options: [:]) { success in
                if !success { setStatus("LAUNCH FAILED", .error) }
            }
        case .freeFireVN:
            attemptSchemes(game.fallbackSchemes, index: 0, game: game)
        }
    }

    private func attemptSchemes(_ schemes: [String], index: Int, game: GameTarget) {
        guard index < schemes.count else {
            setStatus("TARGET NOT FOUND", .error); return
        }
        guard let url = URL(string: schemes[index]) else {
            attemptSchemes(schemes, index: index + 1, game: game); return
        }
        UIApplication.shared.open(url, options: [:]) { success in
            if !success { self.attemptSchemes(schemes, index: index + 1, game: game) }
        }
    }

    private func prepareAndLoadPatches() {
        patchStore.reload()
        syncPatchStates()
    }

    private func syncPatchStates() {
        let snapshot = patchStore.items.map { item in
            (id: item.id, filename: item.packageURL.lastPathComponent)
        }

        DispatchQueue.global(qos: .utility).async {
            var states: [String: Bool] = [:]
            for item in snapshot {
                states[item.filename] =
                    DevicePatchService.latestReceipt(projectID: item.id) != nil
            }
            DispatchQueue.main.async {
                patchStates = states
            }
        }
    }

    private func togglePatch(packageFilename: String) {
        guard !patchOperationBusy else { return }

        guard let item = patchStore.items.first(where: {
            $0.packageURL.lastPathComponent.caseInsensitiveCompare(packageFilename) == .orderedSame
        }) else {
            setStatus("ERROR: Không tìm thấy gói patch", .error)
            return
        }

        let project   = item.project
        let projectID = item.id
        let filename  = item.packageURL.lastPathComponent

        patchOperationBusy = true
        setStatus("PROCESSING: \(filename)", .info)

        DispatchQueue.global(qos: .userInitiated).async {
            defer {
                DispatchQueue.main.async {
                    patchOperationBusy = false
                    syncPatchStates()
                }
            }

            do {
                if let receipt = DevicePatchService.latestReceipt(projectID: projectID) {
                    try DevicePatchService.restore(receipt: receipt)
                    DispatchQueue.main.async {
                        patchStates[filename] = false
                        setStatus("RESTORED: \(filename)", .success)
                        haptic(.success)
                    }
                    return
                }

                guard let project else {
                    DispatchQueue.main.async {
                        setStatus("ERROR: File không hợp lệ hoặc cần mật khẩu", .error)
                        haptic(.error)
                    }
                    return
                }

                _ = try DevicePatchService.apply(project: project)
                let isActive = DevicePatchService.latestReceipt(projectID: projectID) != nil

                DispatchQueue.main.async {
                    patchStates[filename] = isActive
                    if isActive {
                        setStatus("PATCH COMPLETED: \(filename)", .success)
                        haptic(.success)
                    } else {
                        setStatus("PATCH RESULT NOT VERIFIED: \(filename)", .warning)
                        haptic(.warning)
                    }
                }
            } catch {
                let message = error.localizedDescription
                DispatchQueue.main.async {
                    setStatus("PATCH ERROR: \(message)", .error)
                    haptic(.error)
                }
            }
        }
    }

    private func disableAll() {
        guard !patchOperationBusy else { return }

        let snapshot = patchStore.items.map { $0.id }
        patchOperationBusy = true
        setStatus("RESTORING ALL PATCHES...", .info)

        DispatchQueue.global(qos: .userInitiated).async {
            var restoredCount = 0
            var failedCount   = 0

            for projectID in snapshot {
                guard let receipt = DevicePatchService.latestReceipt(projectID: projectID) else {
                    continue
                }
                do {
                    try DevicePatchService.restore(receipt: receipt)
                    restoredCount += 1
                } catch {
                    failedCount += 1
                }
            }

            DispatchQueue.main.async {
                syncPatchStates()
                if failedCount == 0 {
                    setStatus("ALL SYSTEMS RESTORED (\(restoredCount))", .success)
                    haptic(.success)
                } else {
                    setStatus("RESTORE WARNING: \(failedCount) FAILED", .error)
                    haptic(.error)
                }
                patchOperationBusy = false
            }
        }
    }

    private func setStatus(_ text: String, _ kind: StatusKind) {
        status = StatusMessage(text: text, kind: kind)
    }

    private func haptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    private var notificationSheet: some View {
        NavigationStack {
            List {
                ForEach(notifications, id: \.self) { Text($0).font(RobotTheme.mono(12)) }
            }
            .navigationTitle("SYSTEM LOGS")
            .preferredColorScheme(.dark)
        }
    }

    private var explorerSheet: some View {
        NavigationStack {
            List {
                ForEach(sortedItems, id: \.id) { item in
                    Text(item.packageURL.lastPathComponent).font(RobotTheme.mono(12))
                }
            }
            .navigationTitle("FILE BROWSER")
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
