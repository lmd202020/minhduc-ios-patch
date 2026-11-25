
import SwiftUI
import Combine

struct HomeTabView: View {

    var onOpenExistingTools: () -> Void = {}

    @EnvironmentObject private var licenseManager: LicenseManager

    @State private var currentTime = Date()
    @State private var hasNewNotifications = true
    @State private var showNotifications = false

    // MARK: - LINKS

    private let tutorialURL = URL(
        string: "https://youtube.com/shorts/FlLGE-K1Gw4?si=7dEQScTkRz2vCEnD"
    )!

    private let antibanURL = URL(
        string: "https://www.mediafire.com/file/zx8en64ubd63wdz/OGIOS-antiban-certificate.mobileconfig/file"
    )!

    private let timer = Timer.publish(
        every: 1,
        on: .main,
        in: .common
    ).autoconnect()

    // MARK: - ROBOT THEME

    private enum RobotTheme {

        static let bg = Color(red: 0.02, green: 0.03, blue: 0.04)
        static let panel = Color(red: 0.05, green: 0.07, blue: 0.09)
        static let border = Color.cyan.opacity(0.25)

        static let neonCyan = Color.cyan
        static let neonRed = Color(red: 1, green: 0.2, blue: 0.4)
        static let neonGreen = Color.green
        static let neonYellow = Color.yellow

        static let textSub = Color.cyan.opacity(0.6)

        static func mono(
            _ size: CGFloat,
            weight: Font.Weight = .regular
        ) -> Font {
            .system(
                size: size,
                weight: weight,
                design: .monospaced
            )
        }
    }

    // MARK: - KEY INFORMATION

    private var keyIsActive: Bool {

        guard licenseManager.isActive else {
            return false
        }

        guard let expiry = licenseManager.expirationDate else {
            return true
        }

        let endOfExpiryDay = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: expiry
        ) ?? expiry

        return endOfExpiryDay > Date()
    }

    private var daysRemaining: Int {

        guard let expiry = licenseManager.expirationDate else {
            return 0
        }

        let endOfExpiryDay = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: expiry
        ) ?? expiry

        let seconds = endOfExpiryDay.timeIntervalSince(Date())

        guard seconds > 0 else {
            return 0
        }

        return Int(ceil(seconds / 86400))
    }

    private var keyStatus: String {

        guard licenseManager.isActive else {
            return "NO KEY"
        }

        return keyIsActive ? "ACTIVE" : "EXPIRED"
    }

    private var keyDescription: String {

        guard licenseManager.isActive else {
            return "CHƯA KÍCH HOẠT"
        }

        guard keyIsActive else {
            return "KEY ĐÃ HẾT HẠN"
        }

        guard licenseManager.expirationDate != nil else {
            return "KEY KHÔNG GIỚI HẠN"
        }

        return daysRemaining == 1
            ? "CÒN 1 NGÀY"
            : "CÒN \(daysRemaining) NGÀY"
    }

    private var expirationText: String {

        guard licenseManager.isActive else {
            return "CHƯA CÓ KEY"
        }

        guard let expiry = licenseManager.expirationDate else {
            return "KHÔNG GIỚI HẠN"
        }

        return expiry.formatted(
            .dateTime
                .day()
                .month()
                .year()
                .locale(Locale(identifier: "vi_VN"))
        )
    }

    private var keyColor: Color {

        guard licenseManager.isActive else {
            return RobotTheme.neonRed
        }

        return keyIsActive
            ? RobotTheme.neonGreen
            : RobotTheme.neonRed
    }

    // MARK: - BODY

    var body: some View {

        ZStack {

            RobotTheme.bg
                .ignoresSafeArea()

            CyberGrid()

            ScrollView(showsIndicators: false) {

                VStack(spacing: 20) {

                    headerSection

                    statusPanelSection

                    keyInformationSection

                    supportUtilitiesSection

                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
        }
        .preferredColorScheme(.dark)

        .onReceive(timer) { value in
            currentTime = value
        }

        .sheet(isPresented: $showNotifications) {
            NotificationListView()
        }
    }

    // MARK: - HEADER

    private var headerSection: some View {

        HStack {

            HStack(spacing: 12) {

                ZStack {

                    Circle()
                        .fill(RobotTheme.panel)
                        .frame(width: 48, height: 48)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(RobotTheme.neonYellow)
                        .shadow(
                            color: RobotTheme.neonYellow.opacity(0.5),
                            radius: 4
                        )
                }
                .overlay {
                    Circle()
                        .stroke(
                            RobotTheme.neonYellow,
                            lineWidth: 1.5
                        )
                }

                VStack(alignment: .leading, spacing: 4) {

                    Text("DASHBOARD")
                        .font(RobotTheme.mono(15, weight: .black))
                        .foregroundStyle(.white)

                    Text("SYSTEM ONLINE")
                        .font(RobotTheme.mono(10, weight: .bold))
                        .foregroundStyle(RobotTheme.neonGreen)
                }
            }

            Spacer()

            Button {

                showNotifications = true
                hasNewNotifications = false

            } label: {

                ZStack(alignment: .topTrailing) {

                    Circle()
                        .fill(RobotTheme.panel)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Circle()
                                .stroke(
                                    RobotTheme.border,
                                    lineWidth: 1
                                )
                        }

                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(RobotTheme.neonYellow)
                        .frame(width: 44, height: 44)

                    if hasNewNotifications {

                        Circle()
                            .fill(RobotTheme.neonRed)
                            .frame(width: 12, height: 12)
                            .overlay {
                                Circle()
                                    .stroke(
                                        RobotTheme.bg,
                                        lineWidth: 2
                                    )
                            }
                            .offset(x: -4, y: 4)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
    }

    // MARK: - STATUS PANEL

    private var statusPanelSection: some View {

        HStack(spacing: 12) {

            // SYSTEM TIME

            VStack(alignment: .leading, spacing: 8) {

                HStack {

                    Image(systemName: "clock.fill")
                        .foregroundStyle(RobotTheme.neonCyan)

                    Text("SYSTEM TIME")
                        .font(RobotTheme.mono(10, weight: .bold))
                        .foregroundStyle(RobotTheme.textSub)
                }

                Text(currentTime, style: .time)
                    .font(RobotTheme.mono(24, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 120)
            .background(RobotTheme.panel)
            .clipShape(CutCornerShape(cut: 12))
            .overlay {
                CutCornerShape(cut: 12)
                    .stroke(
                        RobotTheme.neonCyan.opacity(0.3),
                        lineWidth: 1
                    )
            }

            // KEY STATUS

            VStack(alignment: .leading, spacing: 8) {

                HStack {

                    Image(systemName: "key.fill")
                        .foregroundStyle(keyColor)

                    Text("KEY STATUS")
                        .font(RobotTheme.mono(10, weight: .bold))
                        .foregroundStyle(RobotTheme.textSub)
                }

                Text(keyStatus)
                    .font(RobotTheme.mono(16, weight: .black))
                    .foregroundStyle(keyColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(keyDescription)
                    .font(RobotTheme.mono(10, weight: .bold))
                    .foregroundStyle(RobotTheme.textSub)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 120)
            .background(RobotTheme.panel)
            .clipShape(CutCornerShape(cut: 12))
            .overlay {
                CutCornerShape(cut: 12)
                    .stroke(
                        keyColor.opacity(0.3),
                        lineWidth: 1
                    )
            }
        }
    }

    // MARK: - KEY INFORMATION

    private var keyInformationSection: some View {

        VStack(alignment: .leading, spacing: 14) {

            HStack(spacing: 8) {

                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(RobotTheme.neonYellow)

                Text("KEY INFORMATION")
                    .font(RobotTheme.mono(13, weight: .black))
                    .foregroundStyle(.white)

                Spacer()

                Text("[ LICENSE ]")
                    .font(RobotTheme.mono(9, weight: .bold))
                    .foregroundStyle(RobotTheme.neonGreen)
            }

            VStack(alignment: .leading, spacing: 15) {

                HStack {

                    VStack(alignment: .leading, spacing: 5) {

                        Text("EXPIRATION DATE")
                            .font(RobotTheme.mono(9, weight: .bold))
                            .foregroundStyle(RobotTheme.textSub)

                        Text(expirationText)
                            .font(RobotTheme.mono(19, weight: .black))
                            .foregroundStyle(
                                keyIsActive
                                    ? RobotTheme.neonYellow
                                    : RobotTheme.neonRed
                            )
                    }

                    Spacer()

                    Image(systemName: "calendar")
                        .font(.system(size: 27, weight: .bold))
                        .foregroundStyle(RobotTheme.neonYellow)
                }

                Rectangle()
                    .fill(RobotTheme.border)
                    .frame(height: 1)

                HStack {

                    VStack(alignment: .leading, spacing: 5) {

                        Text("REMAINING TIME")
                            .font(RobotTheme.mono(9, weight: .bold))
                            .foregroundStyle(RobotTheme.textSub)

                        Text(
                            licenseManager.isActive
                            ? (
                                licenseManager.expirationDate == nil
                                ? "UNLIMITED"
                                : "\(daysRemaining) NGÀY"
                            )
                            : "CHƯA KÍCH HOẠT"
                        )
                        .font(RobotTheme.mono(17, weight: .black))
                        .foregroundStyle(keyColor)
                    }

                    Spacer()

                    Image(systemName: "hourglass")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(keyColor)
                }

                HStack(spacing: 7) {

                    Circle()
                        .fill(keyColor)
                        .frame(width: 7, height: 7)

                    Text(
                        licenseManager.isActive && keyIsActive
                        ? "LICENSE VERIFIED"
                        : "LICENSE NOT ACTIVE"
                    )
                    .font(RobotTheme.mono(9, weight: .bold))
                    .foregroundStyle(keyColor)

                    Spacer()
                }
            }
            .padding(16)
            .background(RobotTheme.panel)
            .clipShape(CutCornerShape(cut: 12))
            .overlay {
                CutCornerShape(cut: 12)
                    .stroke(
                        RobotTheme.neonYellow.opacity(0.25),
                        lineWidth: 1
                    )
            }
        }
    }

    // MARK: - SUPPORT UTILITIES

    private var supportUtilitiesSection: some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 8) {

                Image(systemName: "square.grid.2x2.fill")
                    .foregroundStyle(RobotTheme.neonCyan)

                Text("SUPPORT & UTILITIES")
                    .font(RobotTheme.mono(14, weight: .black))
                    .foregroundStyle(.white)

                Spacer()

                Text("[ ONLINE ]")
                    .font(RobotTheme.mono(9, weight: .bold))
                    .foregroundStyle(RobotTheme.neonGreen)
            }

            VStack(spacing: 12) {

                utilityLink(
                    title: "HƯỚNG DẪN CÀI ĐẶT",
                    subtitle: "WATCH YOUTUBE TUTORIAL",
                    icon: "play.rectangle.fill",
                    color: RobotTheme.neonCyan,
                    url: tutorialURL
                )

                utilityLink(
                    title: "ANTIBAN",
                    subtitle: "TẢI HỒ SƠ CÀI ĐẶT",
                    icon: "shield.lefthalf.filled",
                    color: RobotTheme.neonGreen,
                    url: antibanURL
                )

                Button(action: onOpenExistingTools) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(RobotTheme.neonYellow)
                            .frame(width: 44, height: 44)
                            .background(RobotTheme.neonYellow.opacity(0.1))
                            .clipShape(CutCornerShape(cut: 8))
                            .overlay(CutCornerShape(cut: 8).stroke(RobotTheme.neonYellow.opacity(0.5), lineWidth: 1))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CÔNG CỤ HỆ THỐNG")
                                .font(RobotTheme.mono(12, weight: .black))
                                .foregroundStyle(.white)
                            Text("MỞ TOÀN BỘ CHỨC NĂNG HIỆN CÓ")
                                .font(RobotTheme.mono(9, weight: .bold))
                                .foregroundStyle(RobotTheme.textSub)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(RobotTheme.neonYellow)
                    }
                    .padding(14)
                    .background(RobotTheme.panel)
                    .clipShape(CutCornerShape(cut: 10))
                    .overlay(CutCornerShape(cut: 10).stroke(RobotTheme.neonYellow.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(RobotButtonStyle())
            }
        }
    }

    // MARK: - UTILITY CARD

    private func utilityLink(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        url: URL
    ) -> some View {

        Link(destination: url) {

            HStack(spacing: 12) {

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1))
                    .clipShape(CutCornerShape(cut: 8))
                    .overlay {
                        CutCornerShape(cut: 8)
                            .stroke(
                                color.opacity(0.5),
                                lineWidth: 1
                            )
                    }

                VStack(alignment: .leading, spacing: 4) {

                    Text(title)
                        .font(RobotTheme.mono(12, weight: .black))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(RobotTheme.mono(9, weight: .bold))
                        .foregroundStyle(RobotTheme.textSub)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(color)
            }
            .padding(14)
            .background(RobotTheme.panel)
            .clipShape(CutCornerShape(cut: 10))
            .overlay {
                CutCornerShape(cut: 10)
                    .stroke(
                        color.opacity(0.25),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(RobotButtonStyle())
    }
}

// MARK: - NOTIFICATION VIEW

struct NotificationListView: View {

    @Environment(\.dismiss) private var dismiss

    private let notifications = [
        "Hệ thống cập nhật phiên bản mới",
        "Chào mừng bạn đến với ứng dụng"
    ]

    var body: some View {

        NavigationStack {

            ZStack {

                Color(red: 0.02, green: 0.03, blue: 0.04)
                    .ignoresSafeArea()

                List {

                    ForEach(notifications, id: \.self) { notification in

                        HStack(spacing: 12) {

                            Circle()
                                .fill(Color.cyan)
                                .frame(width: 8, height: 8)

                            Text(notification)
                                .font(
                                    .system(
                                        size: 14,
                                        design: .monospaced
                                    )
                                )
                                .foregroundStyle(.white)
                        }
                        .listRowBackground(
                            Color(red: 0.05, green: 0.07, blue: 0.09)
                        )
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("SYSTEM LOGS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .navigationBarTrailing) {

                    Button("CLOSE") {
                        dismiss()
                    }
                    .foregroundStyle(.cyan)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
