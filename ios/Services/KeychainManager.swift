// Services/KeychainManager.swift

import Foundation
import Security

enum KeychainError: Error {
    case unexpectedStatus(OSStatus)
    case noData
    case invalidData
}

final class KeychainManager {
    static let shared = KeychainManager()
    private init() {}

    private let service = Bundle.main.bundleIdentifier ?? "BudgetTracker"


    func save(_ value: String, forKey key: String) throws {
        let data = Data(value.utf8)

        let deleteQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData: data
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func get(forKey key: String) throws -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else {
            throw KeychainError.noData
        }
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        guard let data = item as? Data,
              let str = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return str
    }

    func delete(forKey key: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: — Convenience для токенів

    func saveAccessToken(_ token: String) {
        try? save(token, forKey: "accessToken")
    }

    func saveRefreshToken(_ token: String) {
        try? save(token, forKey: "refreshToken")
    }

    func getAccessToken() -> String? {
        try? get(forKey: "accessToken")
    }

    func getRefreshToken() -> String? {
        try? get(forKey: "refreshToken")
    }

    func deleteTokens() {
        try? delete(forKey: "accessToken")
        try? delete(forKey: "refreshToken")
    }
}
