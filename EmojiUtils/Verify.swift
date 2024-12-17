//
//  Verify.swift
//  EmojiUtils
//
//  Created by nichokas on 17/12/24.
//

import SwiftUI
import CommonCrypto
import UniformTypeIdentifiers

struct VerifyView: View {
    @State private var inputText: String = ""
    @State private var inputHash: String = ""
    @State private var emojiToVerify: String = ""
    @State private var verificationResult: VerificationResult?
    @State private var isFileImporterPresented: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var currentFileName: String?
    @State private var currentFileData: Data?
    @State private var showSHA: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    enum VerificationResult {
        case match
        case mismatch
        case invalid
    }
    
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
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Verify Hashmoji")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                VStack(spacing: 16) {
                    // Text Input or File Indicator
                    HStack {
                        ZStack(alignment: .leading) {
                            if currentFileName != nil {
                                FileIndicator(
                                    fileName: currentFileName ?? "File",
                                    colorScheme: colorScheme,
                                    onClose: clearFile  // Usar la nueva función
                                )
                            }
                            TextField("Type text to verify...", text: $inputText)
                                .font(.system(size: 18))
                                .textFieldStyle(PlainTextFieldStyle())
                                .opacity(currentFileName == nil ? 1 : 0)
                                .onChange(of: inputText) { newValue in
                                    if newValue.isEmpty {
                                        currentFileName = nil
                                        verificationResult = nil
                                    }
                                    if !newValue.isEmpty {
                                        verifyText(newValue)
                                    }
                                }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(cardBackgroundColor)
                        )
                        
                        Button(action: {
                            isFileImporterPresented.toggle()
                        }) {
                            Image(systemName: "folder")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    
                    // Emoji Input
                    TextField("Paste emojis to verify...", text: $emojiToVerify)
                        .font(.system(size: 24))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(cardBackgroundColor)
                        )
                        .onChange(of: emojiToVerify) { newValue in
                            if let fileData = currentFileData {
                                verifyData(fileData)
                            } else if !inputText.isEmpty {
                                verifyText(inputText)
                            }
                        }
                    
                    // SHA256 Toggle Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showSHA.toggle()
                        }
                    }) {
                        Text(showSHA ? "Hide SHA256" : "Show SHA256")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.white)
                            .frame(minWidth: 120)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.secondary)
                            .cornerRadius(10)
                    }
                    
                    if showSHA {
                        TextField("Paste SHA256 hash...", text: $inputHash)
                            .font(.system(size: 14, design: .monospaced))
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(cardBackgroundColor)
                            )
                            .onChange(of: inputHash) { newValue in
                                if let fileData = currentFileData {
                                    verifyData(fileData)
                                } else if !inputText.isEmpty {
                                    verifyText(inputText)
                                }
                            }
                            .transition(.opacity.combined(with: .slide))
                    }
                    
                    // Verification Result
                    if let result = verificationResult {
                        VStack(spacing: 8) {
                            Image(systemName: resultIcon(for: result))
                                .font(.system(size: 48))
                                .foregroundColor(resultColor(for: result))
                            
                            Text(resultMessage(for: result))
                                .font(.headline)
                                .foregroundColor(resultColor(for: result))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(cardBackgroundColor)
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                NavigationLink(destination: ContentView()) {
                    HStack {
                        Image(systemName: "number")
                        Text("Switch to Hash")
                    }
                    .foregroundColor(.blue)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(cardBackgroundColor)
                    )
                }
                .padding(.bottom)
            }
            .padding(.top, 60)
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func verifyText(_ text: String) {
        let data = Data(text.utf8)
        verifyData(data)
    }
    
    private func verifyData(_ data: Data) {
        // Generamos el hash del archivo o texto actual
        var hash = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { dataBuffer in
            hash.withUnsafeMutableBytes { hashBuffer in
                _ = CC_SHA256(dataBuffer.baseAddress, CC_LONG(data.count), hashBuffer.bindMemory(to: UInt8.self).baseAddress)
            }
        }
        
        // Convertimos el hash a emojis y string
        let emojiList = HashmojiHelper.getEmojiList()
        let calculatedEmojis = HashmojiHelper.hashToEmojis(
            hashData: hash,
            emojiList: emojiList,
            count: 4
        )
        let calculatedHash = hash.map { String(format: "%02hhx", $0) }.joined()
        
        // Limpiamos los inputs (eliminamos espacios en blanco)
        let cleanedEmojiToVerify = emojiToVerify.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedInputHash = inputHash.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Debug prints
        print("Calculated Emojis:", calculatedEmojis)
        print("Emojis to Verify:", cleanedEmojiToVerify)
        print("Calculated Hash:", calculatedHash)
        print("Hash to Verify:", cleanedInputHash)
        
        // Verificación
        if cleanedEmojiToVerify.isEmpty && cleanedInputHash.isEmpty {
            verificationResult = .invalid
            return
        }
        
        // Verificación de emojis y/o hash
        if !cleanedEmojiToVerify.isEmpty && !cleanedInputHash.isEmpty {
            // Verificar ambos
            let emojisMatch = calculatedEmojis == cleanedEmojiToVerify
            let hashMatch = calculatedHash.lowercased() == cleanedInputHash.lowercased()
            verificationResult = (emojisMatch && hashMatch) ? .match : .mismatch
        } else if !cleanedEmojiToVerify.isEmpty {
            // Solo verificar emojis
            verificationResult = (calculatedEmojis == cleanedEmojiToVerify) ? .match : .mismatch
        } else if !cleanedInputHash.isEmpty {
            // Solo verificar hash
            verificationResult = (calculatedHash.lowercased() == cleanedInputHash.lowercased()) ? .match : .mismatch
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedFile = urls.first else { return }
            
            if !selectedFile.startAccessingSecurityScopedResource() {
                showError = true
                errorMessage = "Cannot access the selected file"
                return
            }
            
            defer {
                selectedFile.stopAccessingSecurityScopedResource()
            }
            
            do {
                let fileData = try Data(contentsOf: selectedFile)
                currentFileName = selectedFile.lastPathComponent
                currentFileData = fileData  // Guardamos los datos del archivo
                inputText = ""
                verifyData(fileData)
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
            
        case .failure(let error):
            showError = true
            errorMessage = error.localizedDescription
        }
    }
    
    private func resultIcon(for result: VerificationResult) -> String {
        switch result {
        case .match:
            return "checkmark.circle.fill"
        case .mismatch:
            return "xmark.circle.fill"
        case .invalid:
            return "exclamationmark.circle.fill"
        }
    }
    
    private func resultColor(for result: VerificationResult) -> Color {
        switch result {
        case .match:
            return .green
        case .mismatch:
            return .red
        case .invalid:
            return .orange
        }
    }
    
    private func resultMessage(for result: VerificationResult) -> String {
        switch result {
        case .match:
            return "Hash verified successfully!"
        case .mismatch:
            return "Hash verification failed"
        case .invalid:
            return "Please enter emojis or SHA256 to verify"
        }
    }
    
    private func clearFile() {
        currentFileName = nil
        currentFileData = nil  // Limpiamos los datos del archivo
        inputText = ""
        verificationResult = nil
    }
}

struct VerifyView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VerifyView()
                .preferredColorScheme(.light)
            VerifyView()
                .preferredColorScheme(.dark)
        }
    }
}

