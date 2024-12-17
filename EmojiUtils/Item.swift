//
//  Item.swift
//  EmojiUtils
//
//  Created by nichokas on 17/12/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
