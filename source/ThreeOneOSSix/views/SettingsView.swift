
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language

    @AppStorage(AppLanguage.storageKey)
    private var languageCode = AppLanguage.english.rawValue

    @State private var updateStatus: String?
    @State private var updateURL: URL?
    @State private var isCheckingUpdate = false

    private func checkUpdateManually() {
        isCheckingUpdate = true
        updateStatus = nil
        updateURL = nil

        Task {
            let outcome = await AppUpdateChecker.checkWithOutcome()

            await MainActor.run {
                isCheckingUpdate = false

                switch outcome {
                case .updateAvailable(let offer):
                    updateStatus = language.text(
                        "settings.update_new",
                        offer.version
                    )
                    updateURL = offer.url

                case .upToDate:
                    updateStatus = language.text("settings.update_latest")

                case .failure(let reason):
                    updateURL = nil

                    switch reason {
                    case .offline:
                        updateStatus = language.text("update.failure.offline")

                    case .httpStatus(let code):
                        updateStatus = language.text(
                            "update.failure.http",
                            Int64(code)
                        )

                    case .badResponse:
                        updateStatus = language.text(
                            "update.failure.bad_response"
                        )

                    case .other(let detail):
                        updateStatus =
                            language.text("update.failure.other")
                            + " " + detail
                    }
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // APP NAME
                Section {
                    HStack(spacing: 14) {
                        AppLogo()

                        VStack(alignment: .leading, spacing: 3) {
                            Text("MinhDuc & HoangAnh")
                                .font(.headline)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // LANGUAGE
                Section(language.text("settings.language")) {
                    Picker(
                        language.text("settings.language"),
                        selection: $languageCode
                    ) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.displayName)
                                .tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                }

                // BACKUP AND SUPPORT
                Section {
                    NavigationLink {
                        BackupCenterView()
                    } label: {
                        Label(
                            language.text("backup.title"),
                            systemImage: "externaldrive.badge.timemachine"
                        )
                    }

                    NavigationLink {
                        AcknowledgementsView()
                    } label: {
                        Label(
                            language.text("ack.title"),
                            systemImage: "heart.text.square.fill"
                        )
                    }

                    RespringButton()
                } header: {
                    Text(language.text("settings.backup"))
                }

                // STORE ICON
                Section {
                    Toggle(
                        isOn: Binding(
                            get: {
                                StoreIconFallbackService.isEnabled
                            },
                            set: {
                                StoreIconFallbackService.setEnabled($0)
                            }
                        )
                    ) {
                        Label(
                            language.text("settings.storeicon_fallback"),
                            systemImage: "network"
                        )
                    }
                } header: {
                    Text("TÙY CHỌN")
                }

                // UPDATE
                Section {
                    Button {
                        checkUpdateManually()
                    } label: {
                        HStack {
                            Label(
                                language.text("settings.check_update"),
                                systemImage: "arrow.triangle.down.circle"
                            )

                            Spacer()

                            if isCheckingUpdate {
                                ProgressView()
                                    .controlSize(.small)
                            } else if let updateStatus {
                                Text(updateStatus)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(isCheckingUpdate)

                    if let updateURL {
                        Link(destination: updateURL) {
                            Label(
                                language.text("update.open_github"),
                                systemImage: "safari"
                            )
                            .foregroundStyle(AppTheme.accent)
                        }
                    }
                } header: {
                    Text(language.text("settings.update_header"))
                } footer: {
                    Text(language.text("settings.update_footer"))
                }

                // DEVICE INFORMATION
                Section(language.text("common.device")) {
                    LabeledContent(
                        language.text("dashboard.hardware_model"),
                        value: AppInfo.displayMachineName
                    )

                    LabeledContent(
                        language.text("settings.ios_version"),
                        value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))"
                    )

                    LabeledContent(
                        language.text("settings.access_backend"),
                        value: SandboxAccess.backend.displayName
                    )

                    LabeledContent(
                        language.text("settings.app_group"),
                        value: appGroupStatus
                    )

                    NavigationLink {
                        SandboxDiagnosticsView()
                    } label: {
                        Label(
                            language.text("sandbox.diag.title"),
                            systemImage: "stethoscope"
                        )
                    }
                }

                // ZALO SUPPORT
                Section {
                    if let destination = URL(
                        string: "https://zalo.me/0358648824"
                    ) {
                        Link(destination: destination) {
                            HStack(spacing: 12) {
                                Image(systemName: "message.fill")
                                    .foregroundStyle(.blue)

                                Text("Zalo")
                                    .fontWeight(.bold)

                                Spacer()

                                Text("0358648824")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                    }
                } header: {
                    Text("LIÊN HỆ HỖ TRỢ")
                } footer: {
                    Text("Liên hệ qua Zalo nếu bạn cần hỗ trợ.")
                }
            }
            .tint(AppTheme.accent)
            .navigationTitle("MinhDuc & HoangAnh")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(language.text("common.done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var appGroupStatus: String {
        guard SandboxAccess.needsWorseQuery else {
            return "—"
        }

        return SandboxAccess.appGroup
            ?? language.text("settings.app_group_missing")
    }
}
