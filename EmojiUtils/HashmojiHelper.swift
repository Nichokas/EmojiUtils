//
//  HashmojiHelper.swift
//  EmojiUtils
//
//  Created by nichokas on 24/12/24.
//

import Foundation

extension String {
    func emojisToHex() -> String? {
        let emojiList = HashmojiHelper.getEmojiList()
        var hexBytes: [UInt8] = []
        
        // Dividir la string en caracteres emoji individuales
        var iterator = self.unicodeScalars.makeIterator()
        while let scalar = iterator.next() {
            let emojiString = String(scalar)
            if let index = emojiList.firstIndex(of: emojiString) {
                // El índice original se obtuvo usando módulo, necesitamos preservar solo el byte
                let byte = UInt8(index % 256)
                hexBytes.append(byte)
            } else {
                return nil
            }
        }
        
        // Convertir los bytes a string hexadecimal
        return hexBytes.map { String(format: "%02X", $0) }.joined()
    }
}
