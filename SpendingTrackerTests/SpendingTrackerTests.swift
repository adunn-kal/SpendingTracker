//
//  SpendingTrackerTests.swift
//  SpendingTrackerTests
//
//  Created by Alexander Dunn on 9/5/26.
//

import Testing
@testable import SpendingTracker

struct SpendingTrackerTests {

    @Test func budgetGoalDirectionUsesIncomeForSavingsAndIncomeGoals() {
        #expect(BudgetGoal(type: .income, amount: 100).isIncomeGoal)
        #expect(BudgetGoal(type: .savings, amount: 100).isIncomeGoal)
        #expect(!BudgetGoal(type: .expense, amount: 100).isIncomeGoal)
    }

    @Test func categoryGoalDirectionFollowsItsTransactionType() {
        let incomeCategoryGoal = BudgetGoal(
            type: .category,
            amount: 100,
            categoryTransactionType: .income
        )
        let expenseCategoryGoal = BudgetGoal(
            type: .category,
            amount: 100,
            categoryTransactionType: .expense
        )

        #expect(incomeCategoryGoal.isIncomeGoal)
        #expect(!expenseCategoryGoal.isIncomeGoal)
    }

}
