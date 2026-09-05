//
//  BudgetGoal.swift
//  SpendingTracker
//

import Foundation
import SwiftData

@Model
final class BudgetGoal {
    var type: BudgetGoalType
    var amount: Double
    /// The transaction type a category goal tracks. Overall goals derive their direction from `type`.
    var categoryTransactionType: TransactionType = TransactionType.expense
    var effectiveStartDate: Date
    /// The first month this version no longer applies. A nil value means it continues indefinitely.
    var effectiveEndDate: Date?

    @Relationship(deleteRule: .nullify)
    var category: Category?

    init(
        type: BudgetGoalType,
        amount: Double,
        category: Category? = nil,
        categoryTransactionType: TransactionType = .expense,
        effectiveStartDate: Date = Calendar.current.startOfMonth(for: .now),
        effectiveEndDate: Date? = nil
    ) {
        self.type = type
        self.amount = amount
        self.category = type == .category ? category : nil
        self.categoryTransactionType = categoryTransactionType
        self.effectiveStartDate = effectiveStartDate
        self.effectiveEndDate = effectiveEndDate
    }

    /// Whether reaching more than the target is favorable for this goal.
    var isIncomeGoal: Bool {
        switch type {
        case .income, .savings:
            true
        case .expense:
            false
        case .category:
            categoryTransactionType == .income
        }
    }

    /// The transaction type used when calculating a category goal's actual amount.
    var trackedTransactionType: TransactionType {
        isIncomeGoal ? .income : .expense
    }
}

enum BudgetGoalType: String, Codable, CaseIterable, Identifiable {
    case savings
    case income
    case expense
    case category

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .savings: "Savings"
        case .income: "Income"
        case .expense: "Expenses"
        case .category: "Category"
        }
    }

    var iconName: String {
        switch self {
        case .savings: "banknote"
        case .income: "arrow.up.circle"
        case .expense: "arrow.down.circle"
        case .category: "tag"
        }
    }
}
