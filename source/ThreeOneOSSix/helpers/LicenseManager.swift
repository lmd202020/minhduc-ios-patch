import Combine
import Foundation
import Security
import UIKit

@MainActor
final class LicenseManager: ObservableObject {

    // Public client endpoint only. Never put ADMIN_SECRET in an iOS app.
    // Administrative routes (/admin/*) must only be called by the private admin site.
    private let workerBaseURL = URL(string: "https://muddy-snow-bf48.minhduc1234509876.workers.dev")!

    private static let offlineGraceDays = 3
    private static let checkInterval: TimeInterval = 60

    @Published private(set) var expirationDate: Date?
    @Published private(set) var isActive = false
    @Published private(set) var isBusy = false
    @Published private(set) var message: String?
    @Published private(set) var contactOwner: String? = "0358648824"
    @Published var rememberKey = true
    @Published var forceLogout = false
    // The current Cloudflare API does not expose announcements. Kept for existing UI compatibility.
    @Published var announcement: Announcement?

    private let keychain = Keychain(service: "com.minhduc.admin.activation")
    private let keyAccount = "license-key"
    private let lastCheckAccount = "license-last-check"

    private var lastAttemptAt: Date?
    private var activeSessionKey: String?
    private var checkTask: Task<Void, Never>?
    private var foregroundObserver: NSObjectProtocol?

    init() {
        // Do not trust a locally remembered key until Cloudflare validates it.
        isActive = false
    }

    var hasRememberedKey: Bool {
        !(keychain.string(keyAccount) ?? "").isEmpty
    }

    func rememberedKey() -> String? {
        keychain.string(keyAccount)
    }

    func refresh() {
        guard let saved = activeSessionKey ?? keychain.string(keyAccount), !saved.isEmpty else {
            isActive = false
            return
        }
        isActive = false
        isBusy = true
        Task { await validateSavedKey(saved) }
    }

    // MARK: - Lifecycle

    func beginLaunchSession() {
        guard let saved = keychain.string(keyAccount), !saved.isEmpty else {
            isActive = false
            message = "Cần nhập key — vui lòng nhập access key"
            return
        }

        isActive = false
        isBusy = true
        message = "Đang xác thực License với máy chủ…"
        Task { await validateSavedKey(saved) }
    }

    private func startPeriodicCheck() {
        stopPeriodicCheck()
        checkTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshFromServer()
                try? await Task.sleep(nanoseconds: UInt64(Self.checkInterval * 1_000_000_000))
            }
        }

        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in await self?.refreshFromServer() }
        }
    }

    private func stopPeriodicCheck() {
        checkTask?.cancel()
        checkTask = nil
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        foregroundObserver = nil
    }

    // MARK: - Activation

    func activate(key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isBusy else { return }

        if let last = lastAttemptAt, Date().timeIntervalSince(last) < 1 {
            message = "Vui lòng chờ một chút rồi thử lại"
            return
        }

        lastAttemptAt = Date()
        isBusy = true
        message = "Đang kích hoạt License…"
        Task { await activateOnCloudflare(trimmed) }
    }

    private func activateOnCloudflare(_ key: String) async {
        defer { isBusy = false }
        do {
            let payload = ["key": key, "deviceId": DeviceID.current]
            let result: LicenseAPIResponse = try await post("/activate", body: payload)
            guard result.success else {
                message = Self.message(for: result.error)
                return
            }

            activeSessionKey = key
            if rememberKey {
                keychain.save(key, account: keyAccount)
            } else {
                keychain.delete(keyAccount)
            }
            activeSessionKey = key
            keychain.save(ISO8601DateFormatter().string(from: Date()), account: lastCheckAccount)
            expirationDate = result.expiresAt.flatMap(Self.parseDate)
            announcement = nil
            isActive = true
            forceLogout = false
            message = expirationDate.map { "Kích hoạt thành công — hết hạn \(Self.formatted($0))" }
                ?? "Kích hoạt thành công"
            startPeriodicCheck()
        } catch {
            message = (error as? LicenseError)?.message ?? "Không thể kết nối License API: \(error.localizedDescription)"
        }
    }

    // MARK: - Validation

    private func validateSavedKey(_ key: String) async {
        defer { isBusy = false }
        do {
            let payload = ["key": key, "deviceId": DeviceID.current]
            let result: LicenseAPIResponse = try await post("/validate", body: payload)
            guard result.success, result.valid == true else {
                forceLogoutNow(reason: Self.message(for: result.error))
                return
            }

            keychain.save(ISO8601DateFormatter().string(from: Date()), account: lastCheckAccount)
            expirationDate = result.expiresAt.flatMap(Self.parseDate)
            announcement = nil
            isActive = true
            forceLogout = false
            message = "License hợp lệ — sẵn sàng sử dụng"
            startPeriodicCheck()
        } catch {
            // On launch, don't unlock the app based only on a local key.
            // For an already active session, retain the existing bounded offline grace period.
            if isActive {
                enforceOfflineGrace()
            } else {
                message = (error as? LicenseError)?.message ?? "Không thể xác thực với máy chủ. Kiểm tra Internet rồi thử lại."
            }
        }
    }

    private func refreshFromServer() async {
        guard let saved = activeSessionKey ?? keychain.string(keyAccount), !saved.isEmpty else {
            if !isActive { return }
            forceLogoutNow(reason: "Không tìm thấy License Key đã lưu")
            return
        }

        do {
            let payload = ["key": saved, "deviceId": DeviceID.current]
            let result: LicenseAPIResponse = try await post("/validate", body: payload)
            guard result.success, result.valid == true else {
                forceLogoutNow(reason: Self.message(for: result.error))
                return
            }

            keychain.save(ISO8601DateFormatter().string(from: Date()), account: lastCheckAccount)
            expirationDate = result.expiresAt.flatMap(Self.parseDate)
            message = "Sẵn sàng sử dụng"
        } catch {
            enforceOfflineGrace()
        }
    }

    private func enforceOfflineGrace() {
        guard let saved = keychain.string(lastCheckAccount),
              let last = ISO8601DateFormatter().date(from: saved) else {
            forceLogoutNow(reason: "Cần kết nối mạng để xác thực lại License")
            return
        }
        if Date().timeIntervalSince(last) / 86_400 > Double(Self.offlineGraceDays) {
            forceLogoutNow(reason: "Quá thời gian xác thực ngoại tuyến. Vui lòng kết nối mạng.")
        }
    }

    private func forceLogoutNow(reason: String) {
        stopPeriodicCheck()
        keychain.delete(keyAccount)
        keychain.delete(lastCheckAccount)
        activeSessionKey = nil
        isActive = false
        expirationDate = nil
        message = reason
        forceLogout = true
    }

    func deactivate() {
        stopPeriodicCheck()
        keychain.delete(keyAccount)
        keychain.delete(lastCheckAccount)
        activeSessionKey = nil
        isActive = false
        expirationDate = nil
        forceLogout = false
        announcement = nil
        message = "Đã xoá kích hoạt"
    }

    // MARK: - Cloudflare Worker API

    private func post(_ path: String, body: [String: String]) async throws -> LicenseAPIResponse {
        let url = workerBaseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw LicenseError(message: "Phản hồi máy chủ không hợp lệ")
        }

        if let decoded = try? JSONDecoder().decode(LicenseAPIResponse.self, from: data) {
            return decoded
        }
        guard (200..<300).contains(http.statusCode) else {
            throw LicenseError(message: "Máy chủ trả về HTTP \(http.statusCode)")
        }
        throw LicenseError(message: "Dữ liệu trả về từ License API không hợp lệ")
    }

    private static func message(for error: String?) -> String {
        switch error {
        case "LICENSE_NOT_FOUND": return "License Key không tồn tại"
        case "LICENSE_REVOKED", "LICENSE_INVALID": return "License đã bị khóa hoặc thu hồi"
        case "LICENSE_EXPIRED": return "License đã hết hạn"
        case "DEVICE_ALREADY_BOUND", "DEVICE_MISMATCH": return "License đã liên kết với thiết bị khác. Liên hệ quản trị viên để đặt lại thiết bị."
        case "INVALID_KEY_OR_DEVICE", "INVALID_INPUT": return "License Key hoặc mã thiết bị không hợp lệ"
        case "ACTIVATION_FAILED": return "Kích hoạt thất bại. Vui lòng thử lại"
        case "UNAUTHORIZED": return "Máy chủ từ chối xác thực quản trị. Ứng dụng không được phép dùng ADMIN_SECRET."
        default: return error ?? "License không hợp lệ hoặc máy chủ không phản hồi"
        }
    }

    // MARK: - Date helpers

    private static func parseDate(_ value: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: value) { return date }
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: value) { return date }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }

    private static func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.timeZone = .current
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }
}

private struct LicenseAPIResponse: Decodable {
    let success: Bool
    let valid: Bool?
    let error: String?
    let expiresAt: String?
}

// MARK: - Existing UI model compatibility

struct Announcement: Codable, Identifiable {
    var id: String { date + title }
    let title: String
    let message: String
    let date: String
    let isUrgent: Bool
}

struct LicenseError: Error {
    let message: String
}

// MARK: - Keychain

struct Keychain {
    let service: String

    private func base(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    func string(_ account: String) -> String? {
        var query = base(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var output: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &output) == errSecSuccess,
              let data = output as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func save(_ value: String, account: String) {
        let data = Data(value.utf8)
        let status = SecItemUpdate(base(account) as CFDictionary,
                                   [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var item = base(account)
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(item as CFDictionary, nil)
        }
    }

    func delete(_ account: String) {
        SecItemDelete(base(account) as CFDictionary)
    }
}

// MARK: - Stable device identifier

enum DeviceID {
    private static let keychain = Keychain(service: "com.minhduc.device")
    private static let account = "device-id"

    static var current: String {
        if let stored = keychain.string(account) { return stored }
        let id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        keychain.save(id, account: account)
        return id
    }
}
