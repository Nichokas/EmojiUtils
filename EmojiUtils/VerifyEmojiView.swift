//
//  VerifyEmojiView.swift
//  EmojiUtils
//
//  Created by nichokas on 24/12/24.
//

import SwiftUI

struct VerifyEmojiView: View {
    @State private var hexInput: String = ""
    @State private var verificationResponse: VerifyIdentityResponse?
    @State private var isLoading = false
    @State private var userInfo: UserInfo?
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Input section
            VStack(alignment: .leading, spacing: 8) {
                Text("Introduce la secuencia hexadecimal")
                    .font(.headline)
                
                TextField("Secuencia hexadecimal", text: $hexInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 20))
                    .autocapitalization(.none)
            }
            .padding(.horizontal)
            
            // Verify button
            Button(action: verifyHexSequence) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text("Verificar")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidHex(hexInput) ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isLoading || !isValidHex(hexInput))
            .padding(.horizontal)
            
            if let response = verificationResponse {
                // Verification result section
                VStack(spacing: 15) {
                    // Status icon and message
                    HStack {
                        Image(systemName: response.verified ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(response.verified ? .green : .red)
                        
                        Text(response.verified ? "Proof válido" : "Proof inválido")
                            .font(.headline)
                    }
                    
                    if response.verified {
                        // Time information
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Creado el:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Image(systemName: "clock")
                                Text("\(formattedTime(response.created_at_utc))")
                            }
                            .font(.system(.body, design: .monospaced))
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        
                        // User information if available
                        if let info = userInfo {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Información del usuario")
                                    .font(.headline)
                                
                                UserInfoRow(icon: "person.fill", title: "Nombre", value: info.name ?? "N/A")
                                UserInfoRow(icon: "envelope.fill", title: "Email", value: info.email ?? "N/A")
                                UserInfoRow(icon: "phone.fill", title: "Teléfono", value: info.phone_number ?? "N/A")
                                UserInfoRow(icon: "key.fill", title: "GPG", value: info.gpg_fingerprint ?? "N/A")
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
                .transition(.opacity)
            }
            
            Spacer()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Error desconocido al verificar la secuencia")
        }
    }
    
    private func isValidHex(_ string: String) -> Bool {
        let hexRegex = "^[0-9A-Fa-f]+$"
        return string.range(of: hexRegex, options: .regularExpression) != nil
    }
    
    private func verifyHexSequence() {
        isLoading = true
        verifyIdentity(emojiSequence: hexInput) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    self.verificationResponse = response
                    if response.verified {
                        fetchUserInfo(publicKey: response.public_key)
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
    
    private func fetchUserInfo(publicKey: String) {
        getUserInfo(publicKey: publicKey) { info in
            DispatchQueue.main.async {
                self.userInfo = info
            }
        }
    }
    
    private func formattedTime(_ utcTime: UTCTime) -> String {
        return String(format: "%02d:%02d:%02d UTC",
                     utcTime.hour,
                     utcTime.minute,
                     utcTime.second)
    }
}

struct UserInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.body)
            }
        }
    }
}
