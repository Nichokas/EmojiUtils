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
                Text("Welcome!")
                    .font(.title)
                
                Text("Public Key: \(publicKey)")
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding()
                
                if let info = userInfo {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("User Information:")
                            .font(.headline)
                        Text("Name: \(info.name ?? "N/A")")
                        Text("Email: \(info.email ?? "N/A")")
                        Text("Phone: \(info.phone_number ?? "N/A")")
                        Text("GPG: \(info.gpg_fingerprint ?? "N/A")")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Button("Update Info") {
                    showingUpdateSheet = true
                }
                .buttonStyle(.bordered)
                
                Button("Create Proof") {
                    createIdentityProof(privateKey: privateKey) { sequence in
                        DispatchQueue.main.async {
                            if let sequence = sequence {
                                self.emojiSequence = sequence
                                self.showingProofTimer = true
                            }
                        }
                    }
                }
                .buttonStyle(.bordered)
                Button("Verify Proof") {
                    showingVerifyView = true
                }
                .buttonStyle(.bordered)
                
                Button("Logout") {
                    logout()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
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
            Form {
                Section(header: Text("Update Information")) {
                    TextField("Name", text: $name)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                    
                    TextField("PGP Fingerprint", text: $pgp)
                    
                }
            }
            .navigationTitle("Update Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    onUpdate()
                }
            )
        }
    }
}
