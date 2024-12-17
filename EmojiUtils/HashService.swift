//
//  HashService.swift
//  EmojiUtils
//
//  Created by nichokas on 17/12/24.
//

import Foundation
import CommonCrypto
import CryptoKit

class HashService {
    static func calculateHash(from text: String) -> (emojis: String, hash: String) {
        let data = Data(text.utf8)
        return calculateHash(from: data)
    }
    
    static func calculateHash(from data: Data) -> (emojis: String, hash: String) {
        var hash = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { dataBuffer in
            hash.withUnsafeMutableBytes { hashBuffer in
                _ = CC_SHA256(dataBuffer.baseAddress, CC_LONG(data.count), hashBuffer.bindMemory(to: UInt8.self).baseAddress)
            }
        }
        
        let emojiList = HashmojiHelper.getEmojiList()
        let emojis = HashmojiHelper.hashToEmojis(
            hashData: hash,
            emojiList: emojiList,
            count: 4
        )
        let hashString = hash.map { String(format: "%02hhx", $0) }.joined()
        
        return (emojis, hashString)
    }
}
