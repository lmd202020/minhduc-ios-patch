import SwiftUI

/// Admin > TỆP: chỉ xem các gói tệp đã có trong thư viện ứng dụng.
/// Không tạo project mới và không tự ý áp dụng tệp vào game.
struct PatchProjectsView: View {
    @StateObject private var store = PatchProjectStore()
    private let onOpenSettings: () -> Void
    private let onOpenLogs: () -> Void

    init(onOpenSettings: @escaping () -> Void = {}, onOpenLogs: @escaping () -> Void = {}) {
        self.onOpenSettings = onOpenSettings
        self.onOpenLogs = onOpenLogs
    }
    @State private var selectedGame: GameTarget?

    private let background = Color(red: 0.02, green: 0.03, blue: 0.04)
    private let panel = Color(red: 0.05, green: 0.07, blue: 0.09)
    private let cyan = Color(red: 0.0, green: 0.9, blue: 1.0)
    private let green = Color(red: 0.2, green: 1.0, blue: 0.4)
    private let pink = Color(red: 1.0, green: 0.2, blue: 0.4)

    private var itemsForSelectedGame: [PatchLibraryItem] {
        guard let selectedGame else { return [] }
        return store.items
            .filter { item in
                let filename = item.packageURL.lastPathComponent.lowercased()
                switch selectedGame {
                case .freeFireTH:
                    return ["(20)", "(21)", "(22)", "(23)", "(24)"].contains {
                        filename.contains($0)
                    }
                case .freeFireVN:
                    return ["aimbody", "aimlock", "aimbot", "antiban", "nhetam"].contains {
                        filename.contains($0)
                    }
                }
            }
            .sorted { $0.packageURL.lastPathComponent < $1.packageURL.lastPathComponent }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                background.ignoresSafeArea()
                CyberGrid()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        if let selectedGame {
                            gameFilesView(for: selectedGame)
                        } else {
                            gamePicker
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("TỆP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedGame != nil {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { self.selectedGame = nil }
                        } label: {
                            Label("GAME", systemImage: "chevron.left")
                                .font(.system(.caption, design: .monospaced).bold())
                        }
                        .tint(cyan)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        store.reload()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .tint(cyan)
                    .accessibilityLabel("Làm mới danh sách tệp")
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private var gamePicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("CHỌN GAME", subtitle: "XEM CÁC TỆP ĐÃ CÓ")

            ForEach(GameTarget.allCases) { game in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedGame = game }
                } label: {
                    HStack(spacing: 14) {
                        AsyncImage(url: URL(string: game.imageURL)) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                Image(systemName: "gamecontroller.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(game.accentColor)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(panel)
                            }
                        }
                        .frame(width: 66, height: 66)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(game.accentColor, lineWidth: 2))

                        VStack(alignment: .leading, spacing: 5) {
                            Text(game.rawValue.uppercased())
                                .font(.system(size: 17, weight: .black, design: .monospaced))
                                .foregroundStyle(.white)
                            Text(game.bundleID)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(cyan.opacity(0.7))
                            Text("\(count(for: game)) TỆP CÓ SẴN")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(green)
                        }
                        Spacer()
                        Image(systemName: "chevron.right.2")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(game.accentColor)
                    }
                    .padding(14)
                    .background(panel)
                    .clipShape(CutCornerShape(cut: 12))
                    .overlay(CutCornerShape(cut: 12).stroke(game.accentColor.opacity(0.45), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Text("Chọn Free Fire TH hoặc Free Fire VN để xem danh sách gói tệp tương ứng.")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.top, 4)
        }
    }

    private func gameFilesView(for game: GameTarget) -> some View {
        let items = itemsForSelectedGame
        let accent = game == .freeFireTH ? cyan : pink

        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader(game.rawValue.uppercased(), subtitle: "TỆP ĐÃ CÓ TRONG THƯ VIỆN")
            HStack {
                Label("\(items.count) FILE", systemImage: "folder.fill")
                Spacer()
                Text(game.bundleID)
            }
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(accent)

            if items.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 34))
                        .foregroundStyle(accent)
                    Text("CHƯA CÓ TỆP")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("Không tìm thấy gói tệp dành cho game này trong thư viện.")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(28)
                .background(panel)
                .clipShape(CutCornerShape(cut: 12))
                .overlay(CutCornerShape(cut: 12).stroke(accent.opacity(0.35), lineWidth: 1))
            } else {
                ForEach(items) { item in
                    HStack(spacing: 12) {
                        Image(systemName: "doc.zipper")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(accent)
                            .frame(width: 42, height: 42)
                            .background(accent.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.packageURL.lastPathComponent)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                            Text(item.project?.name ?? (item.isLocked ? "GÓI ĐÃ KHÓA" : "PATCH PACKAGE"))
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundStyle(item.isLocked ? .yellow : accent.opacity(0.8))
                        }
                        Spacer(minLength: 4)
                        Image(systemName: item.isLocked ? "lock.fill" : "checkmark.circle.fill")
                            .foregroundStyle(item.isLocked ? .yellow : green)
                    }
                    .padding(12)
                    .background(panel)
                    .clipShape(CutCornerShape(cut: 10))
                    .overlay(CutCornerShape(cut: 10).stroke(accent.opacity(0.3), lineWidth: 1))
                }
            }
        }
    }

    private func count(for game: GameTarget) -> Int {
        let keys: [String]
        switch game {
        case .freeFireTH: keys = ["(20)", "(21)", "(22)", "(23)", "(24)"]
        case .freeFireVN: keys = ["aimbody", "aimlock", "aimbot", "antiban", "nhetam"]
        }
        return store.items.filter { item in
            let name = item.packageURL.lastPathComponent.lowercased()
            return keys.contains { name.contains($0) }
        }.count
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 17, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(cyan.opacity(0.75))
            }
            Spacer()
            Circle().fill(green).frame(width: 8, height: 8)
        }
    }
}
