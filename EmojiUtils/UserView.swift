//
//  UserView.swift
//  EmojiUtils
//
//  Created by nichokas on 20/12/24.
//

import SwiftUI

struct UserView: View {
    @State private var publicKey: String = ""
    @State private var privateKey: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("Welcome!")
                .font(.title)
            
            // Display the public key (you might want to mask it partially)
            Text("Public Key: \(publicKey)")
                .padding()
            
            // Add a logout button
            Button("Logout") {
                logout()
            }
            .padding()
        }
        .onAppear {
            loadKeys()
        }
    }
    
    private func loadKeys() {
        // Load keys from Keychain
        if let pubKey = KeychainHelper.standard.read(forKey: "public_key"),
           let privKey = KeychainHelper.standard.read(forKey: "private_key") {
            publicKey = pubKey
            privateKey = privKey
        }
    }
    
    private func logout() {
        // Clear keys from Keychain
        KeychainHelper.standard.delete(forKey: "public_key")
        KeychainHelper.standard.delete(forKey: "private_key")
        
        // Dismiss the view and go back to login
        presentationMode.wrappedValue.dismiss()
    }
    
    // Function to perform operations with the keys
    private func performOperation() {
        // Example of how to use the keys for operations
        // You can access publicKey and privateKey here
        // For example:
        login(pub_key: publicKey, priv_key: privateKey) { isValid in
            // Handle the response
        }
    }
}
