//
//  Category.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftData
import SwiftUI

@Model
class Category {
    var name: String
    var icon: String        // SF Symbol name
    var colorHex: String    // stored as hex string, converted to Color for charts/UI
    
    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction] = []
    
    init(name: String, icon: String, colorHex: String) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
    }
}
