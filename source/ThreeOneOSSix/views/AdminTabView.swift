
import SwiftUI
import UIKit

// MARK: - LICENSE HELPERS

private extension LicenseManager {

    var daysRemaining: Int? {
        guard let exp = expirationDate else { return nil }
        let end = exp.addingTimeInterval(86_400)
        return max(0, Int(ceil(end.timeIntervalSinceNow / 86_400)))
    }

    var maskedKey: String {
        guard let key = rememberedKey(), !key.isEmpty else {
            return "—"
        }

        guard key.count > 8 else {
            return String(repeating: "•", count: key.count)
        }

        return String(key.prefix(4))
            + String(repeating: "•", count: key.count - 8)
            + String(key.suffix(4))
    }

    var contact: String {
        contactOwner ?? "0358648824"
    }
}

// MARK: - BUILD INFO

private enum BuildInfo {
    static var version: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "?"
    }

    static var build: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "?"
    }
}

// MARK: - ADMIN SHEET

private enum AdminSheet: String, Identifiable {
    case projects
    case license

    var id: String { rawValue }
}

// MARK: - ROBOT THEME

private enum AdminRobotTheme {
    static let bg = Color(red: 0.02, green: 0.03, blue: 0.04)
    static let panel = Color(red: 0.05, green: 0.07, blue: 0.09)

    static let cyan = Color(red: 0.0, green: 0.9, blue: 1.0)
    static let green = Color(red: 0.2, green: 1.0, blue: 0.4)
    static let red = Color(red: 1.0, green: 0.2, blue: 0.4)
    static let yellow = Color(red: 1.0, green: 0.8, blue: 0.0)

    static let subText = cyan.opacity(0.6)

    static func mono(
        _ size: CGFloat,
        weight: Font.Weight = .regular
    ) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - ADMIN TAB

struct AdminTabView: View {

    @EnvironmentObject private var licenseManager: LicenseManager
    @Environment(\.openURL) private var openURL

    @State private var sheet: AdminSheet?
    @State private var showDeactivateAlert = false

    // THAY LINK ẢNH CỦA BẠN VÀO ĐÂY
    private let adminImageURL = URL(
        string: "https://cdn.upanhlaylink.com/i/uD56WSYY.jpeg"
    )

    var body: some View {
        ZStack {
            AdminRobotTheme.bg.ignoresSafeArea()
            CyberGrid()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    profileHeader

                    if let announcement = licenseManager.announcement {
                        announcementCard(announcement)
                    }

                    licenseStatusCard
                    adminOptions
                    zaloCard
                    footerSection

                    Spacer().frame(height: 30)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $sheet) { item in
            switch item {
            case .license:
                LicenseInfoView()

            case .projects:
                PatchProjectsView()
            }
        }
        .alert("Xoá kích hoạt?", isPresented: $showDeactivateAlert) {
            Button("Huỷ", role: .cancel) {}

            Button("Xoá", role: .destructive) {
                licenseManager.deactivate()
            }
        } message: {
            Text("Bạn sẽ cần nhập lại Key để vào ứng dụng.")
        }
    }

    // MARK: PROFILE HEADER

    private var profileHeader: some View {
        VStack(spacing: 12) {

            ZStack {
                Circle()
                    .fill(AdminRobotTheme.yellow.opacity(0.15))
                    .frame(width: 112, height: 112)
                    .blur(radius: 14)

                Circle()
                    .stroke(AdminRobotTheme.yellow, lineWidth: 2)
                    .frame(width: 94, height: 94)

                AsyncImage(url: adminImageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .failure, .empty:
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(20)
                            .foregroundStyle(AdminRobotTheme.yellow)

                    @unknown default:
                        Image(systemName: "person.fill")
                            .foregroundStyle(AdminRobotTheme.yellow)
                    }
                }
                .frame(width: 84, height: 84)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(AdminRobotTheme.yellow, lineWidth: 2)
                }
            }

            Text("ADMIN MINHDUC")
                .font(AdminRobotTheme.mono(18, weight: .black))
                .tracking(1.5)
                .foregroundStyle(.white)

            Text("DEVELOPER • PATCH MASTER")
                .font(AdminRobotTheme.mono(10, weight: .bold))
                .tracking(1)
                .foregroundStyle(AdminRobotTheme.yellow)

            HStack(spacing: 8) {
                statusBadge(
                    icon: "crown.fill",
                    title: "PREMIUM ADMIN",
                    color: AdminRobotTheme.yellow
                )

                expiryBadge
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(AdminRobotTheme.panel)
        .clipShape(CutCornerShape(cut: 16))
        .overlay {
            CutCornerShape(cut: 16)
                .stroke(
                    AdminRobotTheme.yellow.opacity(0.55),
                    lineWidth: 1
                )
        }
    }

    private func statusBadge(
        icon: String,
        title: String,
        color: Color
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
            Text(title).tracking(0.5)
        }
        .font(AdminRobotTheme.mono(8, weight: .black))
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
        .overlay {
            Capsule().stroke(color.opacity(0.4), lineWidth: 1)
        }
    }

    private var expiryBadge: some View {
        let days = licenseManager.daysRemaining

        let color: Color = {
            guard let days else { return AdminRobotTheme.green }
            return days == 0
                ? AdminRobotTheme.red
                : (days <= 7 ? AdminRobotTheme.yellow : AdminRobotTheme.green)
        }()

        let title = days.map {
            $0 == 0 ? "HẾT HẠN" : "CÒN \($0) NGÀY"
        } ?? "VĨNH VIỄN"

        return statusBadge(
            icon: "clock.fill",
            title: title,
            color: color
        )
    }

    // MARK: LICENSE STATUS

    private var licenseStatusCard: some View {
        VStack(alignment: .leading, spacing: 14) {

            sectionTitle(
                icon: "key.fill",
                title: "LICENSE INFORMATION",
                color: AdminRobotTheme.green
            )

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("KEY STATUS")
                        .font(AdminRobotTheme.mono(9, weight: .bold))
                        .foregroundStyle(AdminRobotTheme.subText)

                    Text(licenseManager.isActive ? "ACTIVE" : "INACTIVE")
                        .font(AdminRobotTheme.mono(17, weight: .black))
                        .foregroundStyle(
                            licenseManager.isActive
                                ? AdminRobotTheme.green
                                : AdminRobotTheme.red
                        )
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("REMAINING")
                        .font(AdminRobotTheme.mono(9, weight: .bold))
                        .foregroundStyle(AdminRobotTheme.subText)

                    Text(
                        licenseManager.daysRemaining.map {
                            "\($0) DAYS"
                        } ?? "UNLIMITED"
                    )
                    .font(AdminRobotTheme.mono(15, weight: .black))
                    .foregroundStyle(AdminRobotTheme.yellow)
                }
            }

            Divider()
                .overlay(AdminRobotTheme.cyan.opacity(0.2))

            HStack {
                Text("LICENSE KEY")
                    .font(AdminRobotTheme.mono(9, weight: .bold))
                    .foregroundStyle(AdminRobotTheme.subText)

                Spacer()

                Text(licenseManager.maskedKey)
                    .font(AdminRobotTheme.mono(11, weight: .bold))
                    .foregroundStyle(.white)
            }

            robotButton(
                icon: "key.fill",
                title: "XEM CHI TIẾT LICENSE",
                subtitle: "LICENSE DETAILS",
                color: AdminRobotTheme.green
            ) {
                sheet = .license
            }
        }
        .padding(15)
        .background(AdminRobotTheme.panel)
        .clipShape(CutCornerShape(cut: 14))
        .overlay {
            CutCornerShape(cut: 14)
                .stroke(AdminRobotTheme.green.opacity(0.3), lineWidth: 1)
        }
    }

    // MARK: ADMIN OPTIONS

    private var adminOptions: some View {
        VStack(alignment: .leading, spacing: 12) {

            sectionTitle(
                icon: "cpu.fill",
                title: "ADMIN CONTROL",
                color: AdminRobotTheme.cyan
            )

            robotButton(
                icon: "folder.fill",
                title: "TỆP",
                subtitle: "XEM TỆP FREE FIRE TH / VN",
                color: AdminRobotTheme.cyan
            ) {
                sheet = .projects
            }

            robotButton(
                icon: "rectangle.portrait.and.arrow.right",
                title: "XOÁ KÍCH HOẠT",
                subtitle: "DEACTIVATE LICENSE",
                color: AdminRobotTheme.red
            ) {
                showDeactivateAlert = true
            }
        }
    }

    // MARK: ROBOT BUTTON

    private func robotButton(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1))
                    .clipShape(CutCornerShape(cut: 8))
                    .overlay {
                        CutCornerShape(cut: 8)
                            .stroke(color.opacity(0.5), lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AdminRobotTheme.mono(12, weight: .black))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(AdminRobotTheme.mono(8, weight: .bold))
                        .foregroundStyle(AdminRobotTheme.subText)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(color)
            }
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(AdminRobotTheme.panel)
            .clipShape(CutCornerShape(cut: 12))
            .overlay {
                CutCornerShape(cut: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(RobotButtonStyle())
    }

    // MARK: ZALO

    private var zaloCard: some View {
        Button {
            if let url = URL(
                string: "https://zalo.me/\(licenseManager.contact)"
            ) {
                openURL(url)
            }
        } label: {
            HStack(spacing: 12) {

                Image(systemName: "message.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AdminRobotTheme.yellow)
                    .frame(width: 44, height: 44)
                    .background(AdminRobotTheme.yellow.opacity(0.1))
                    .clipShape(CutCornerShape(cut: 8))
                    .overlay {
                        CutCornerShape(cut: 8)
                            .stroke(
                                AdminRobotTheme.yellow.opacity(0.5),
                                lineWidth: 1
                            )
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text("LIÊN HỆ ADMIN MINHDUC")
                        .font(AdminRobotTheme.mono(11, weight: .black))
                        .foregroundStyle(.white)

                    Text(licenseManager.contact)
                        .font(AdminRobotTheme.mono(10, weight: .bold))
                        .foregroundStyle(AdminRobotTheme.subText)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .foregroundStyle(AdminRobotTheme.yellow)
            }
            .padding(13)
            .background(AdminRobotTheme.panel)
            .clipShape(CutCornerShape(cut: 12))
            .overlay {
                CutCornerShape(cut: 12)
                    .stroke(AdminRobotTheme.yellow.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(RobotButtonStyle())
    }

    // MARK: ANNOUNCEMENT

    private func announcementCard(_ a: Announcement) -> some View {
        let color = a.isUrgent
            ? AdminRobotTheme.red
            : AdminRobotTheme.yellow

        return HStack(alignment: .top, spacing: 12) {
            Image(
                systemName: a.isUrgent
                    ? "exclamationmark.triangle.fill"
                    : "megaphone.fill"
            )
            .foregroundStyle(color)
            .font(.system(size: 18, weight: .bold))

            VStack(alignment: .leading, spacing: 5) {
                Text(a.title)
                    .font(AdminRobotTheme.mono(12, weight: .black))
                    .foregroundStyle(.white)

                Text(a.message)
                    .font(AdminRobotTheme.mono(10))
                    .foregroundStyle(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)

                Text(a.date)
                    .font(AdminRobotTheme.mono(9, weight: .bold))
                    .foregroundStyle(color)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AdminRobotTheme.panel)
        .clipShape(CutCornerShape(cut: 12))
        .overlay {
            CutCornerShape(cut: 12)
                .stroke(color.opacity(0.4), lineWidth: 1)
        }
    }

    // MARK: SECTION TITLE

    private func sectionTitle(
        icon: String,
        title: String,
        color: Color
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)

            Text(title)
                .font(AdminRobotTheme.mono(13, weight: .black))
                .foregroundStyle(.white)

            Spacer()
        }
    }

    // MARK: FOOTER

    private var footerSection: some View {
        VStack(spacing: 8) {
            Divider()
                .overlay(AdminRobotTheme.yellow.opacity(0.2))

            Text("DEVELOPED BY ADMIN MINHDUC")
                .font(AdminRobotTheme.mono(10, weight: .black))
                .foregroundStyle(.white.opacity(0.65))

            Text("VERSION \(BuildInfo.version) • BUILD \(BuildInfo.build)")
                .font(AdminRobotTheme.mono(9, weight: .bold))
                .foregroundStyle(AdminRobotTheme.subText)

            HStack(spacing: 6) {
                Circle()
                    .fill(
                        licenseManager.isActive
                            ? AdminRobotTheme.green
                            : AdminRobotTheme.red
                    )
                    .frame(width: 7, height: 7)

                Text(
                    licenseManager.isActive
                        ? "LICENSE ACTIVE"
                        : "LICENSE INACTIVE"
                )
                .font(AdminRobotTheme.mono(9, weight: .black))
                .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 5)
    }
}

// MARK: - LICENSE INFO VIEW

struct LicenseInfoView: View {

    @EnvironmentObject private var licenseManager: LicenseManager
    @Environment(\.dismiss) private var dismiss

    @State private var showDeactivateAlert = false
    @State private var copied = false

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                AdminRobotTheme.bg.ignoresSafeArea()
                CyberGrid()

                ScrollView {
                    VStack(spacing: 14) {
                        infoCard
                        deviceCard

                        Button {
                            showDeactivateAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "xmark.shield.fill")

                                Text("XOÁ KÍCH HOẠT")
                                    .font(AdminRobotTheme.mono(12, weight: .black))

                                Spacer()

                                Image(systemName: "arrow.up.right")
                            }
                            .foregroundStyle(AdminRobotTheme.red)
                            .padding(15)
                            .background(AdminRobotTheme.panel)
                            .clipShape(CutCornerShape(cut: 12))
                            .overlay {
                                CutCornerShape(cut: 12)
                                    .stroke(
                                        AdminRobotTheme.red.opacity(0.4),
                                        lineWidth: 1
                                    )
                            }
                        }
                        .buttonStyle(RobotButtonStyle())
                    }
                    .padding(16)
                }
            }
            .navigationTitle("LICENSE INFO")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("ĐÓNG") {
                        dismiss()
                    }
                    .foregroundStyle(AdminRobotTheme.cyan)
                }
            }
            .alert("Xoá kích hoạt?", isPresented: $showDeactivateAlert) {
                Button("Huỷ", role: .cancel) {}

                Button("Xoá", role: .destructive) {
                    licenseManager.deactivate()
                    dismiss()
                }
            } message: {
                Text("Bạn sẽ cần nhập lại Key để vào ứng dụng.")
            }
        }
        .preferredColorScheme(.dark)
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("KEY INFORMATION")
                .font(AdminRobotTheme.mono(13, weight: .black))
                .foregroundStyle(AdminRobotTheme.green)

            infoRow(
                title: "KEY",
                value: licenseManager.maskedKey
            )

            infoRow(
                title: "STATUS",
                value: licenseManager.isActive ? "ACTIVE" : "INACTIVE"
            )

            infoRow(
                title: "EXPIRATION",
                value: expiryText
            )

            infoRow(
                title: "REMAINING",
                value: licenseManager.daysRemaining.map {
                    "\($0) DAYS"
                } ?? "UNLIMITED"
            )
        }
        .padding(15)
        .background(AdminRobotTheme.panel)
        .clipShape(CutCornerShape(cut: 12))
        .overlay {
            CutCornerShape(cut: 12)
                .stroke(AdminRobotTheme.green.opacity(0.3), lineWidth: 1)
        }
    }

    private var deviceCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("DEVICE INFORMATION")
                .font(AdminRobotTheme.mono(13, weight: .black))
                .foregroundStyle(AdminRobotTheme.cyan)

            Text(DeviceID.current)
                .font(AdminRobotTheme.mono(10, weight: .medium))
                .foregroundStyle(.white)
                .textSelection(.enabled)

            Button {
                UIPasteboard.general.string = DeviceID.current

                UINotificationFeedbackGenerator()
                    .notificationOccurred(.success)

                copied = true
            } label: {
                HStack {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")

                    Text(copied ? "ĐÃ SAO CHÉP" : "SAO CHÉP DEVICE ID")
                        .font(AdminRobotTheme.mono(10, weight: .black))
                }
                .foregroundStyle(AdminRobotTheme.cyan)
            }

            ShareLink(item: DeviceID.current) {
                Label(
                    "GỬI DEVICE ID CHO ADMIN",
                    systemImage: "square.and.arrow.up"
                )
                .font(AdminRobotTheme.mono(10, weight: .black))
                .foregroundStyle(AdminRobotTheme.yellow)
            }

            Text(
                "Mỗi Key chỉ sử dụng trên một thiết bị. Khi đổi máy, hãy liên hệ Admin để được hỗ trợ chuyển Key."
            )
            .font(AdminRobotTheme.mono(9))
            .foregroundStyle(AdminRobotTheme.subText)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AdminRobotTheme.panel)
        .clipShape(CutCornerShape(cut: 12))
        .overlay {
            CutCornerShape(cut: 12)
                .stroke(AdminRobotTheme.cyan.opacity(0.3), lineWidth: 1)
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(AdminRobotTheme.mono(9, weight: .bold))
                .foregroundStyle(AdminRobotTheme.subText)

            Spacer()

            Text(value)
                .font(AdminRobotTheme.mono(10, weight: .black))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
        }
    }

    private var expiryText: String {
        licenseManager.expirationDate.map {
            Self.dateFormatter.string(from: $0)
        } ?? "Không giới hạn"
    }
}
