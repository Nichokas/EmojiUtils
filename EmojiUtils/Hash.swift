//
//  Hash.swift
//  EmojiUtils
//
//  Created by nichokas on 17/12/24.
//

import SwiftUI
import CommonCrypto
import UniformTypeIdentifiers

// MARK: - Helpers and extensions
extension String {
    func sha256() -> Data {
        let data = Data(self.utf8)
        var hash = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        
        _ = hash.withUnsafeMutableBytes { hashBytes in
            data.withUnsafeBytes { dataBytes in
                CC_SHA256(dataBytes.baseAddress, CC_LONG(data.count), hashBytes.bindMemory(to: UInt8.self).baseAddress)
            }
        }
        return hash
    }
}

struct HashmojiHelper {
    static func getEmojiList() -> [String] {
        var emojis: [String] = []
        let ranges = [
            0x1F300...0x1F5FF,
            0x1F600...0x1F64F,
            0x1F680...0x1F6FF,
            0x1F700...0x1F77F,
            0x1F780...0x1F7FF,
            0x1F800...0x1F8FF,
            0x1F900...0x1F9FF,
            0x1FA70...0x1FAFF
        ]
        
        for range in ranges {
            for codePoint in range {
                if let scalar = UnicodeScalar(codePoint), scalar.properties.isEmoji {
                    emojis.append(String(scalar))
                }
            }
        }
        return emojis
    }
    
    static func hashToEmojis(hashData: Data, emojiList: [String], count: Int) -> String {
        let totalEmojis = emojiList.count
        var emojis = ""
        let bytes = Array(hashData)
        
        for i in 0..<min(count, bytes.count) {
            let index = Int(bytes[i]) % totalEmojis
            emojis += emojiList[index]
        }
        
        return emojis
    }
}

struct FileIndicator: View {
    var fileName: String
    var colorScheme: ColorScheme
    var onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.fill")
                .font(.system(size: 14))
            Text(fileName)
                .font(.system(size: 14))
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
        )
        .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.8))
    }
}
