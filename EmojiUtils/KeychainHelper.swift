import Foundation
import Security

class KeychainHelper {
    static let standard = KeychainHelper()
    private init() {}

    // Save to keychain
    func save(_ data: String, forKey key: String) {
        guard let data = data.data(using: .utf8) else { return }

        // Delete any existing keys for that key
        delete(forKey: key)

        // Create the query to add the new data
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Add the data to the keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error saving data to keychain: \(status)")
        }
    }

    // Read data from the keychain
    func read(forKey key: String) -> String? {
        // Create the query to search for the data
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        // Check if the data was found
        guard status == errSecSuccess, let data = item as? Data else {
            print("Error reading data from keychain: \(status)")
            return nil
        }

        // Convert the data to a string
        return String(data: data, encoding: .utf8)
    }

    // Delete data from the keychain
    func delete(forKey key: String) {
        // Create the query to identify the data to delete
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        // Delete the data from the keychain
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            print("Error deleting data from keychain: \(status)")
        }
    }
}
