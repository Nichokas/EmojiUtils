//
//  AuthManager.swift
//  EmojiUtils
//
//  Created by nichokas on 22/12/24.
//

import Foundation

class AuthManager {
    // Verify if there are any key on the keychain
    static func userIsLoggedIn() -> Bool {
        guard
            let _ = KeychainHelper.standard.read(forKey: "public_key"),
            let _ = KeychainHelper.standard.read(forKey: "private_key")
        else {
            return false
        }
        return true
    }
}
