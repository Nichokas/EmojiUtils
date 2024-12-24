import Foundation

extension String {
    func emojisToHex() -> String? {
        let emojiList = HashmojiHelper.getEmojiList()
        var hexBytes: [UInt8] = []
        
        // Split the string into individual emoji characters
        var iterator = self.unicodeScalars.makeIterator()
        while let scalar = iterator.next() {
            let emojiString = String(scalar)
            if let index = emojiList.firstIndex(of: emojiString) {
                // The original index was obtained using modulo, we need to preserve only the byte
                let byte = UInt8(index % 256)
                hexBytes.append(byte)
            } else {
                return nil
            }
        }
        
        // Convert the bytes to a hexadecimal string
        return hexBytes.map { String(format: "%02X", $0) }.joined()
    }
}
