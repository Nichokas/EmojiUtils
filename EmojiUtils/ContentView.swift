//
//  ContentView.swift
//  EmojiUtils
//
//  Created by nichokas on 17/12/24.
//

import SwiftUI
import CommonCrypto
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var inputText: String = ""
    @State private var emojiRepresentation: String = ""
    @State private var showSHA: Bool = false
    @State private var currentHash: String = ""
    @State private var isShowingCopyConfirmation: Bool = false
    @State private var isFileImporterPresented: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var currentFileName: String?
    @State private var showVerifyView: Bool = false
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
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Hashmoji")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    VStack(spacing: 8) {
                        HStack {
                            ZStack(alignment: .leading) {
                                if currentFileName != nil {
                                    FileIndicator(
                                        fileName: currentFileName ?? "File",
                                        colorScheme: colorScheme,
                                        onClose: {
                                            currentFileName = nil
                                            inputText = ""
                                            updateEmoji(text: "")
                                        }
                                    )
                                }
                                TextField("Type something...", text: $inputText)
                                    .font(.system(size: 18))
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .opacity(currentFileName == nil ? 1 : 0)
                                    .onChange(of: inputText) { newValue in
                                        if newValue.isEmpty {
                                            currentFileName = nil
                                        }
                                        updateEmoji(text: newValue)
                                    }
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
                    }
                    .padding(.horizontal, 20)
                    
                    if !emojiRepresentation.isEmpty {
                        VStack(spacing: 16) {
                            Text(emojiRepresentation)
                                .font(.system(size: 56))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(cardBackgroundColor)
                                        .shadow(
                                            color: colorScheme == .dark
                                            ? Color.white.opacity(0.05)
                                            : Color.black.opacity(0.1),
                                            radius: 8
                                        )
                                )
                            
                            HStack(spacing: 10) {
                                Button(action: {
                                    UIPasteboard.general.string = emojiRepresentation
                                }) {
                                    Text("Copy")
                                        .font(.system(.body, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(minWidth: 120)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                }
                                
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
                            }
                            
                            if showSHA {
                                VStack {
                                    Text("SHA256:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(currentHash)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(cardBackgroundColor)
                                                .shadow(
                                                    color: colorScheme == .dark
                                                    ? Color.white.opacity(0.05)
                                                    : Color.black.opacity(0.1),
                                                    radius: 4
                                                )
                                        )
                                        .onLongPressGesture {
                                            UIPasteboard.general.string = currentHash
                                            isShowingCopyConfirmation = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                isShowingCopyConfirmation = false
                                            }
                                        }
                                }
                                .transition(.opacity.combined(with: .slide))
                                .overlay(
                                    Group {
                                        if isShowingCopyConfirmation {
                                            Text("SHA256 Copied!")
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .background(Color.green)
                                                .cornerRadius(8)
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                )
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Button to change to the verification view
                    HStack{
                        NavigationLink(destination: VerifyView()) {
                            HStack {
                                Image(systemName: "checkmark.shield")
                                Text("Switch to verify")
                            }.foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12).fill(cardBackgroundColor))
                        }
                        NavigationLink(destination: IdentityCheckView()) {
                            HStack {
                                Image(systemName: "person.badge.key")
                                Text("Switch to identity")
                            }
                            .foregroundColor(.blue)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(cardBackgroundColor)
                            )
                        }
                    }
                    .padding(.bottom)
                }
                .padding(.top, 60)
            }
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
    
    private func updateEmoji(text: String) {
        let data = Data(text.utf8)
        updateEmojiFromData(data)
    }
    
    private func updateEmojiFromData(_ data: Data) {
        var hash = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { dataBuffer in
            hash.withUnsafeMutableBytes { hashBuffer in
                _ = CC_SHA256(dataBuffer.baseAddress, CC_LONG(data.count), hashBuffer.bindMemory(to: UInt8.self).baseAddress)
            }
        }
        
        let emojiList = HashmojiHelper.getEmojiList()
        emojiRepresentation = HashmojiHelper.hashToEmojis(
            hashData: hash,
            emojiList: emojiList,
            count: 4
        )
        
        currentHash = hash.map { String(format: "%02hhx", $0) }.joined()
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
                updateEmojiFromData(fileData)
                currentFileName = selectedFile.lastPathComponent
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
            
        case .failure(let error):
            showError = true
            errorMessage = error.localizedDescription
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .preferredColorScheme(.light)
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

