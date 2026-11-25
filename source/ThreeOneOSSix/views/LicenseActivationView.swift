import SwiftUI

/// License-key entry UI. Verification is delegated to LicenseManager/backend.
struct LicenseActivationView: View {
    @EnvironmentObject private var licenseManager: LicenseManager
    @Environment(\.dismiss) private var dismiss
    @State private var key = ""
    @FocusState private var keyFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AdminRobotTheme.bg.ignoresSafeArea()
                CyberGrid()
                ScrollView {
                    VStack(spacing: 18) {
                        Image(systemName: "key.horizontal.fill")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(AdminRobotTheme.yellow)
                            .padding(.top, 24)

                        Text("KÍCH HOẠT LICENSE")
                            .font(AdminRobotTheme.mono(20, weight: .black))
                            .foregroundStyle(.white)

                        Text("Nhập access key được cấp để xác thực thiết bị.")
                            .font(AdminRobotTheme.mono(11))
                            .foregroundStyle(AdminRobotTheme.subText)
                            .multilineTextAlignment(.center)

                        TextField("Nhập license key", text: $key)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .focused($keyFocused)
                            .font(AdminRobotTheme.mono(14, weight: .bold))
                            .padding(15)
                            .background(AdminRobotTheme.panel)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AdminRobotTheme.cyan.opacity(0.5)))
                            .foregroundStyle(.white)

                        Toggle("Lưu key trên thiết bị", isOn: $licenseManager.rememberKey)
                            .font(AdminRobotTheme.mono(11, weight: .semibold))
                            .tint(AdminRobotTheme.green)
                            .foregroundStyle(.white)

                        Button {
                            keyFocused = false
                            licenseManager.activate(key: key)
                        } label: {
                            HStack {
                                if licenseManager.isBusy { ProgressView().tint(.black) }
                                Text(licenseManager.isBusy ? "ĐANG XÁC THỰC…" : "XÁC THỰC KEY")
                                    .font(AdminRobotTheme.mono(13, weight: .black))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .foregroundStyle(.black)
                            .background(AdminRobotTheme.cyan)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || licenseManager.isBusy)

                        if let message = licenseManager.message {
                            Text(message)
                                .font(AdminRobotTheme.mono(11, weight: .semibold))
                                .foregroundStyle(licenseManager.isActive ? AdminRobotTheme.green : AdminRobotTheme.yellow)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(AdminRobotTheme.panel)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Text("Lưu ý: ứng dụng cần backend xác thực được cấu hình an toàn. Không đặt GitHub token bí mật trong mã nguồn iOS.")
                            .font(AdminRobotTheme.mono(9))
                            .foregroundStyle(AdminRobotTheme.subText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                }
            }
            .navigationTitle("LICENSE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("ĐÓNG") { dismiss() }
                        .foregroundStyle(AdminRobotTheme.cyan)
                }
            }
            .onChange(of: licenseManager.isActive) { active in
                if active { dismiss() }
            }
        }
        .preferredColorScheme(.dark)
    }
}
