//
//  LoginView.swift
//  EmojiUtils
//
//  Created by nichokas on 19/12/24.
//

import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @State private var pub_key: String = ""
    @State private var priv_key: String = ""
    @State private var showError: Bool = false
    @State private var navigateToUserView: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    private var backgroundColor: LinearGradient {
        switch colorScheme {
        case .light:
            return LinearGradient(
                gradient: Gradient(colors: [Color.white, Color(uiColor: .systemGray6)]),
                startPoint: .top,
                endPoint: .bottom
            )
        case .dark:
            return LinearGradient(
                gradient: Gradient(colors: [Color(uiColor: .systemGray6), Color.black]),
                startPoint: .top,
                endPoint: .bottom
            )
        @unknown default:
            return LinearGradient(
                gradient: Gradient(colors: [Color.white, Color(uiColor: .systemGray6)]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(uiColor: .systemGray5) : .white
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Identity login")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    VStack(spacing: 8) {
                        HStack {
                            ZStack(alignment: .leading) {
                                TextField("Public key", text: $pub_key)
                                    .textFieldStyle(PlainTextFieldStyle())
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(cardBackgroundColor)
                                    .shadow(
                                        color: colorScheme == .dark
                                            ? Color.white.opacity(0.05)
                                            : Color.black.opacity(0.1),
                                        radius: 5,
                                        x: 0,
                                        y: 2
                                    )
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        HStack {
                            ZStack(alignment: .leading) {
                                SecureField("Private key", text: $priv_key)
                                    .textFieldStyle(PlainTextFieldStyle())
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(cardBackgroundColor)
                                    .shadow(
                                        color: colorScheme == .dark
                                            ? Color.white.opacity(0.05)
                                            : Color.black.opacity(0.1),
                                        radius: 5,
                                        x: 0,
                                        y: 2
                                    )
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Button(action: loginAPI) {
                        Label("Import keypair", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .alert("Invalid keys", isPresented: $showError) {
                        Button("OK", role: .cancel) {}
                    }
                    
                    NavigationLink(
                        destination: UserView(),
                        isActive: $navigateToUserView,
                        label: { EmptyView() }
                    )
                }
            }
        }
    }
    
    private func loginAPI() {
        login(pub_key: pub_key, priv_key: priv_key) { isValid in
            DispatchQueue.main.async {
                if isValid {
                    // Guardar las claves de manera segura en el Keychain
                    KeychainHelper.standard.save(pub_key, forKey: "public_key")
                    KeychainHelper.standard.save(priv_key, forKey: "private_key")
                    
                    // Navegar a UserView
                    navigateToUserView = true
                } else {
                    showError = true
                }
            }
        }
    }
}
