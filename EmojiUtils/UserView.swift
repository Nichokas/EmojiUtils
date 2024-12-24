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
    @State private var userInfo: UserInfo? = nil
    @State private var showingUpdateSheet = false
    @State private var showingIdentityProof = false
    @State private var emojiSequence: String = ""
    @State private var isVerifying = false
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingProofTimer = false
    @State private var showingVerifyView = false
    
    // New state variables for updating user info
    @State private var newEmail: String = ""
    @State private var newPhoneNumber: String = ""
    @State private var newName: String = ""
    @State private var newPGP: String = ""
    
    var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    VStack(spacing: 15) {
                        Text("Welcome!")
                            .font(.title)
                            .bold()
                        
                        // Public Key Display
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Public Key")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Image(systemName: "key.fill")
                                    .foregroundColor(.blue)
                                Text(publicKey)
                                    .font(.system(.body, design: .monospaced))
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.bottom)
                    
                    // User Information Section
                    if let info = userInfo {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                                Text("User Information")
                                    .font(.headline)
                            }
                            
                            VStack(spacing: 15) {
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
                    
                    // Actions Section
                    VStack(spacing: 15) {
                        // Update Info Button
                        Button(action: { showingUpdateSheet = true }) {
                            HStack {
                                Image(systemName: "pencil.circle.fill")
                                Text("Update Info")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        // Create Proof Button
                        Button(action: {
                            createIdentityProof(privateKey: privateKey) { sequence in
                                DispatchQueue.main.async {
                                    if let sequence = sequence {
                                        self.emojiSequence = sequence
                                        self.showingProofTimer = true
                                    }
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "shield.fill")
                                Text("Create Proof")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        // Verify Proof Button
                        Button(action: { showingVerifyView = true }) {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                Text("Verify Proof")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        // Logout Button
                        Button(action: logout) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Logout")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.top)
                }
                .padding()
            }
        .onAppear {
            loadKeys()
            fetchUserInfo()
        }
        .sheet(isPresented: $showingUpdateSheet) {
            UpdateInfoView(name: $newName, email: $newEmail, phoneNumber: $newPhoneNumber, pgp: $newPGP) {
                updateUserInformation()
            }
        }
        .sheet(isPresented: $showingProofTimer) {
            ProofTimerView(hexSequence: emojiSequence)
        }
        .sheet(isPresented: $showingVerifyView) {
            VerifyEmojiView()
        }
        .alert("Identity Verification", isPresented: $showingIdentityProof) {
            Button("Verify") {
                verifyIdentityConfirmation()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your emoji sequence is: \(emojiSequence)\nPlease verify this sequence.")
        }
    }
    
    private func loadKeys() {
        if let pubKey = KeychainHelper.standard.read(forKey: "public_key"),
           let privKey = KeychainHelper.standard.read(forKey: "private_key") {
            publicKey = pubKey
            privateKey = privKey
        }
    }
    
    private func fetchUserInfo() {
        getUserInfo(publicKey: publicKey) { info in
            DispatchQueue.main.async {
                self.userInfo = info
                if let email = info?.email {
                    self.newEmail = email
                }
                if let phone = info?.phone_number {
                    self.newPhoneNumber = phone
                }
                if let name = info?.name {
                    self.newName = name
                }
                if let pgp = info?.gpg_fingerprint {
                    self.newPGP = pgp
                }
            }
        }
    }
    
    private func updateUserInformation() {
        updateUserInfo(privateKey: privateKey, email: newEmail, phoneNumber: newPhoneNumber, name: newName, pgp: newPGP) { success in
            DispatchQueue.main.async {
                if success {
                    fetchUserInfo()
                    showingUpdateSheet = false
                }
            }
        }
    }
    
    private func verifyIdentityProcess() {
        createIdentityProof(privateKey: privateKey) { sequence in
            DispatchQueue.main.async {
                if let sequence = sequence {
                    self.emojiSequence = sequence
                    self.showingIdentityProof = true
                }
            }
        }
    }
    
    private func verifyIdentityConfirmation() {
        verifyIdentity(emojiSequence: emojiSequence) { success in
            DispatchQueue.main.async {
                self.isVerifying = false
            }
        }
    }
    
    private func logout() {
        KeychainHelper.standard.delete(forKey: "public_key")
        KeychainHelper.standard.delete(forKey: "private_key")
        presentationMode.wrappedValue.dismiss()
    }
}

struct UpdateInfoView: View {
    @Binding var name: String
    @Binding var email: String
    @Binding var phoneNumber: String
    @Binding var pgp: String
    
    let onUpdate: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 15) {
                        InfoField(icon: "person.fill", title: "Name", text: $name)
                        InfoField(icon: "envelope.fill", title: "Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                        InfoField(icon: "phone.fill", title: "Phone", text: $phoneNumber)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                        InfoField(icon: "key.fill", title: "PGP Fingerprint", text: $pgp)
                    }
                    .padding()
                    
                    Button(action: {
                        onUpdate()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Changes")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .navigationTitle("Update Profile")
                .navigationBarItems(leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
    }

    // Nuevo componente para campos de información
    struct InfoField: View {
        let icon: String
        let title: String
        @Binding var text: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                    TextField(title, text: $text)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
