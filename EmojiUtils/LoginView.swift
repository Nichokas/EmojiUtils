//
//  LoginView.swift
//  EmojiUtils
//
//  Created by nichokas on 17/12/24.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss
    @State private var username = ""
    @State private var isRegistering = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Username", text: $username)
                }
                
                Button(isRegistering ? "Register" : "Login") {
                    Task {
                        do {
                            if isRegistering {
                                try await authService.register(username: username)
                            }
                            try await authService.authenticate()
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
                .disabled(username.isEmpty)
                
                Button(isRegistering ? "Already have an account?" : "Need to register?") {
                    isRegistering.toggle()
                }
            }
            .navigationTitle(isRegistering ? "Register" : "Login")
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}
