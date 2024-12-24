//
//  VerifyEmojiView.swift
//  EmojiUtils
//
//  Created by nichokas on 24/12/24.
//

import SwiftUI

struct VerifyEmojiView: View {
    @State private var emojiInput: String = "" // Cambiar hexInput por emojiInput
    @State private var verificationResponse: VerifyIdentityResponse?
    @State private var isLoading = false
    @State private var userInfo: UserInfo?
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    VStack(spacing: 15) {
                        Text("Verify Identity")
                            .font(.title)
                            .bold()
                        
                        Text("Introduce la secuencia de emojis para verificar la identidad")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Input Section
                    VStack(spacing: 15) {
                        TextField("Secuencia de emojis", text: $emojiInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 24))
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .onChange(of: emojiInput) { newValue in
                                if !isValidEmojiSequence(newValue) {
                                    errorMessage = "Por favor, introduce solo emojis válidos"
                                    showError = true
                                }
                            }
                        
                        if !emojiInput.isEmpty {
                            Text("\(emojiInput.count) emojis introducidos")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Verify Button
                    Button(action: verifyEmojiSequence) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            }
                            Image(systemName: "checkmark.shield.fill")
                            Text("Verificar")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(!emojiInput.isEmpty ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading || emojiInput.isEmpty)
                    .padding(.horizontal)
                    
                    // Results Section
                    if let response = verificationResponse {
                        VStack(spacing: 20) {
                            // Status Section
                            VStack(spacing: 15) {
                                HStack {
                                    Image(systemName: response.verified ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(response.verified ? .green : .red)
                                    
                                    Text(response.verified ? "Proof válido" : "Proof inválido")
                                        .font(.title2)
                                        .bold()
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .padding(.top, 40)
                            .padding(.bottom, 20)
                            
                            if response.verified {
                                // Time Information
                                VStack(spacing: 10) {
                                    Text("Creado el")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    
                                    HStack {
                                        Image(systemName: "clock")
                                            .font(.system(size: 20))
                                        Text(formattedTime(response.created_at_utc))
                                            .font(.system(.title3, design: .monospaced))
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                                
                                // User Information
                                if let info = userInfo {
                                    VStack(alignment: .leading, spacing: 15) {
                                        Text("Información del usuario")
                                            .font(.headline)
                                            .padding(.bottom, 5)
                                        
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
            }
            .safeAreaInset(edge: .top) { // Esto asegura que respetamos el área segura superior
                Color.clear.frame(height: 1)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Error desconocido al verificar la secuencia")
            }
        }

    private func verifyEmojiSequence() {
        print("Secuencia de emojis original: \(emojiInput)") // Debug
        
        guard let hexSequence = emojiInput.emojisToHex() else {
            errorMessage = "Secuencia de emojis inválida"
            showError = true
            return
        }
        
        print("Secuencia convertida a hex: \(hexSequence)") // Debug
        isLoading = true
        
        verifyIdentity(emojiSequence: hexSequence) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    if response.verified {
                        print("Verificación exitosa con clave pública: \(response.public_key)")
                        self.verificationResponse = response
                        fetchUserInfo(publicKey: response.public_key)
                    } else {
                        self.errorMessage = response.message ?? "Verificación fallida"
                        self.showError = true
                    }
                case .failure(let error):
                    print("Error en la verificación: \(error)")
                    self.errorMessage = "Error al verificar: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }

    // Función para validar que solo se introduzcan emojis válidos
    private func isValidEmoji(_ emoji: String) -> Bool {
        let emojiList = HashmojiHelper.getEmojiList()
        return emojiList.contains(emoji)
    }

    private func isValidEmojiSequence(_ input: String) -> Bool {
        return input.unicodeScalars.allSatisfy { scalar in
            isValidEmoji(String(scalar))
        }
    }
    
    
    private func fetchUserInfo(publicKey: String) {
        getUserInfo(publicKey: publicKey) { info in
            DispatchQueue.main.async {
                self.userInfo = info
            }
        }
    }
    
    private func formattedTime(_ utcTime: UTCTime?) -> String {
        guard let utcTime = utcTime else {
            return "Tiempo no disponible"
        }
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
