import SwiftUI

struct VerifyEmojiView: View {
    @State private var emojiInput: String = "" // Change hexInput to emojiInput
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
                        
                        Text("Enter the emoji sequence to verify identity")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Input Section
                    VStack(spacing: 15) {
                        TextField("Emoji sequence", text: $emojiInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 24))
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .onChange(of: emojiInput) { newValue in
                                if !isValidEmojiSequence(newValue) {
                                    errorMessage = "Please enter only valid emojis"
                                    showError = true
                                }
                            }
                        
                        if !emojiInput.isEmpty {
                            Text("\(emojiInput.count) emojis entered")
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
                            Text("Verify")
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
                                    
                                    Text(response.verified ? "Valid proof" : "Invalid proof")
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
                                    Text("Created on")
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
                                        Text("User Information")
                                            .font(.headline)
                                            .padding(.bottom, 5)
                                        
                                        UserInfoRow(icon: "person.fill", title: "Name", value: info.name ?? "N/A")
                                        UserInfoRow(icon: "envelope.fill", title: "Email", value: info.email ?? "N/A")
                                        UserInfoRow(icon: "phone.fill", title: "Phone", value: info.phone_number ?? "N/A")
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
            .safeAreaInset(edge: .top) { // This ensures we respect the top safe area
                Color.clear.frame(height: 1)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error verifying the sequence")
            }
        }

    private func verifyEmojiSequence() {
        guard let hexSequence = emojiInput.emojisToHex() else {
            errorMessage = "Invalid emoji sequence"
            showError = true
            return
        }
        
        isLoading = true
        
        verifyIdentity(emojiSequence: hexSequence) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    if response.verified {
                        self.verificationResponse = response
                        fetchUserInfo(publicKey: response.public_key)
                    } else {
                        self.errorMessage = response.message ?? "Verification failed"
                        self.showError = true
                    }
                case .failure(let error):
                    self.errorMessage = "Error verifying: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }

    // Function to validate that only valid emojis are entered
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
            return "Time not available"
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
