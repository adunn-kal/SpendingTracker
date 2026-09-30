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
    var name: String = ""
    var icon: String = "folder"
    var colorHex: String = "#000000"
    
    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]? = []
    
    @Relationship(deleteRule: .nullify)
    var budgetGoals: [BudgetGoal]? = []
    
    init(name: String, icon: String, colorHex: String) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
    }
}
