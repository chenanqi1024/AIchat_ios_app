import Combine
import Foundation
import Security

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var accessToken: String?
    @Published private(set) var user: AppUser?

    private let tokenStore = KeychainTokenStore(service: "AIchat", account: "accessToken")
    private let userDefaults = UserDefaults.standard

    var isAuthenticated: Bool {
        accessToken?.isEmpty == false
    }

    init() {
        accessToken = tokenStore.read()
        user = readUser()
    }

    func update(with session: LoginSession) {
        accessToken = session.accessToken
        user = session.user
        try? tokenStore.save(session.accessToken)
        persist(user: session.user)
    }

    func clear() {
        accessToken = nil
        user = nil
        tokenStore.delete()
        userDefaults.removeObject(forKey: "auth.user.id")
        userDefaults.removeObject(forKey: "auth.user.countryCode")
        userDefaults.removeObject(forKey: "auth.user.phoneNumber")
    }

    private func persist(user: AppUser) {
        userDefaults.set(user.id, forKey: "auth.user.id")
        userDefaults.set(user.countryCode, forKey: "auth.user.countryCode")
        userDefaults.set(user.phoneNumber, forKey: "auth.user.phoneNumber")
    }

    private func readUser() -> AppUser? {
        let id = userDefaults.integer(forKey: "auth.user.id")
        guard id > 0,
              let countryCode = userDefaults.string(forKey: "auth.user.countryCode"),
              let phoneNumber = userDefaults.string(forKey: "auth.user.phoneNumber") else {
            return nil
        }
        return AppUser(id: id, countryCode: countryCode, phoneNumber: phoneNumber)
    }
}

private final class KeychainTokenStore {
    let service: String
    let account: String

    init(service: String, account: String) {
        self.service = service
        self.account = account
    }

    func save(_ token: String) throws {
        delete()
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw APIError.transport(message: "Token 保存失败")
        }
    }

    func read() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
