//
//  Item.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
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
