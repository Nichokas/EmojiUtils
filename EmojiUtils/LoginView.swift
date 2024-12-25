import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @State private var priv_key: String = ""
    @State private var showError: Bool = false
    @State private var navigateToUserView: Bool = false
    @State private var showingRegistrationSheet: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    // States for registration form
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var gpgFingerprint: String = ""
    @State private var registrationError: String = ""
    @State private var showRegistrationError: Bool = false
    
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
                    
                    HStack(spacing: 10) {
                        Button(action: loginAPI) {
                            Label("Import keypair", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { showingRegistrationSheet = true }) {
                            Label("Create new keypair", systemImage: "plus.circle")
                        }
                        .buttonStyle(.bordered)
                    }
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
        .sheet(isPresented: $showingRegistrationSheet) {
            RegistrationView(isPresented: $showingRegistrationSheet)
        }
    }
    
    private func loginAPI() {
        login(priv_key: priv_key) { isValid, publicKey in
            DispatchQueue.main.async {
                if isValid, let publicKey = publicKey {
                    // Save the keys securely in the Keychain
                    KeychainHelper.standard.save(publicKey, forKey: "public_key")
                    KeychainHelper.standard.save(priv_key, forKey: "private_key")
                    
                    // Para verificar que se guardaron correctamente (opcional, puedes removerlo)
                    if let savedPublicKey = KeychainHelper.standard.read(forKey: "public_key"),
                       let savedPrivateKey = KeychainHelper.standard.read(forKey: "private_key") {
                        print("Keys saved successfully:")
                        print("Public Key: \(savedPublicKey)")
                        print("Private Key: \(savedPrivateKey)")
                    }
                    
                    // Navigate to UserView
                    navigateToUserView = true
                } else {
                    showError = true
                }
            }
        }
    }

}


struct RegistrationView: View {
    @Binding var isPresented: Bool
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var gpgFingerprint: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showingSuccessAlert: Bool = false
    @State private var navigateToUserView: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("GPG Fingerprint", text: $gpgFingerprint)
                        .autocapitalization(.none)
                }
                
                Section {
                    Button(action: registerUser) {
                        Text("Create Keypair")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Create New Keypair")
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            })
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    isPresented = false
                    // Después de cerrar el alert de éxito, navegamos a UserView
                    navigateToUserView = true
                }
            } message: {
                Text("Your keypair has been created successfully. The keys have been saved to your keychain.")
            }
            
            NavigationLink(destination: UserView(), isActive: $navigateToUserView) {
                EmptyView()
            }
        }
    }
    private func registerUser() {
        register(
            name: name,
            email: email,
            phoneNumber: phoneNumber,
            gpgFingerprint: gpgFingerprint
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Save the keys to the keychain
                    KeychainHelper.standard.save(response.public_key, forKey: "public_key")
                    KeychainHelper.standard.save(response.private_key, forKey: "private_key")
                    
                    // Print para debug
                    print("Keys saved successfully:")
                    print("Public key: \(response.public_key)")
                    print("Private key: \(response.private_key)")
                    
                    // Verificar que las keys se guardaron correctamente
                    if let savedPubKey = KeychainHelper.standard.read(forKey: "public_key"),
                       let savedPrivKey = KeychainHelper.standard.read(forKey: "private_key") {
                        print("Keys retrieved from keychain:")
                        print("Public key: \(savedPubKey)")
                        print("Private key: \(savedPrivKey)")
                    }
                    
                    showingSuccessAlert = true
                case .failure(let error):
                    showError = true
                    errorMessage = error.localizedDescription
                    print("Registration error: \(error.localizedDescription)")
                }
            }
        }
    }
}
