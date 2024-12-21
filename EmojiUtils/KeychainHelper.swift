//
//  KeychainHelper.swift
//  EmojiUtils
//
//  Created by nichokas on 21/12/24.
//

import Foundation
import Security

class KeychainHelper {
    static let standard = KeychainHelper()
    private init() {}

    // Guardar datos en el llavero
    func save(_ data: String, forKey key: String) {
        guard let data = data.data(using: .utf8) else { return }

        // Eliminar cualquier dato existente con la misma clave
        delete(forKey: key)

        // Crear la consulta para agregar el nuevo dato
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Agregar el dato al llavero
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error al guardar el dato en el llavero: \(status)")
        }
    }

    // Leer datos del llavero
    func read(forKey key: String) -> String? {
        // Crear la consulta para buscar el dato
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        // Verificar si se encontró el dato
        guard status == errSecSuccess, let data = item as? Data else {
            print("Error al leer el dato del llavero: \(status)")
            return nil
        }

        // Convertir los datos a una cadena de texto
        return String(data: data, encoding: .utf8)
    }

    // Eliminar datos del llavero
    func delete(forKey key: String) {
        // Crear la consulta para identificar el dato a eliminar
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        // Eliminar el dato del llavero
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            print("Error al eliminar el dato del llavero: \(status)")
        }
    }
}
