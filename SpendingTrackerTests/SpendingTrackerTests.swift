//
//  SpendingTrackerTests.swift
//  SpendingTrackerTests
//
//  Created by Alexander Dunn on 9/5/26.
//

import Foundation
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

    @Test func csvExportFormatsExpensesAsNegativeAndIncomeAsPositive() {
        let exportView = ExportTransactionsView()
        let category = Category(name: "Groceries", icon: "cart", colorHex: "#FF3B30")
        
        let components = DateComponents(year: 2026, month: 9, day: 15)
        let testDate = Calendar.current.date(from: components)!
        
        let incomeTx = Transaction(date: testDate, amount: 1500.0, type: .income, note: "Paycheck", category: category)
        let expenseTx = Transaction(date: testDate, amount: 85.50, type: .expense, note: "Supermarket", category: category)
        
        let occurrences = [
            TransactionOccurrence(transaction: incomeTx, date: testDate),
            TransactionOccurrence(transaction: expenseTx, date: testDate)
        ]
        
        let csv = exportView.generateCSV(from: occurrences)
        let lines = csv.components(separatedBy: "\n")
        
        #expect(lines.count == 3)
        #expect(lines[0] == "Date,Category,Amount,Note")
        #expect(lines.contains("09/15/2026,Groceries,1500.00,Paycheck"))
        #expect(lines.contains("09/15/2026,Groceries,-85.50,Supermarket"))
    }

    @Test func csvExportEscapesSpecialCharactersInFields() {
        let exportView = ExportTransactionsView()
        let category = Category(name: "Food, & Dining", icon: "cart", colorHex: "#FF3B30")
        
        let components = DateComponents(year: 2026, month: 9, day: 20)
        let testDate = Calendar.current.date(from: components)!
        
        let expenseTx = Transaction(date: testDate, amount: 42.0, type: .expense, note: "Dinner at \"Joe's\"", category: category)
        let occurrences = [TransactionOccurrence(transaction: expenseTx, date: testDate)]
        
        let csv = exportView.generateCSV(from: occurrences)
        let lines = csv.components(separatedBy: "\n")
        
        #expect(lines.count == 2)
        #expect(lines[1] == "09/20/2026,\"Food, & Dining\",-42.00,\"Dinner at \"\"Joe's\"\"\"")
    }

    @Test func transactionOccurrencesInDateRangeFilterCorrectly() {
        let cal = Calendar.current
        let sep1 = cal.date(from: DateComponents(year: 2026, month: 9, day: 1))!
        let sep15 = cal.date(from: DateComponents(year: 2026, month: 9, day: 15))!
        let sep30 = cal.date(from: DateComponents(year: 2026, month: 9, day: 30))!
        
        let tx1 = Transaction(date: sep1, amount: 100, type: .expense)
        let tx2 = Transaction(date: sep15, amount: 200, type: .expense)
        let tx3 = Transaction(date: sep30, amount: 300, type: .expense)
        let all = [tx1, tx2, tx3]
        
        let rangeOccurrences = all.occurrences(from: cal.date(from: DateComponents(year: 2026, month: 9, day: 10))!,
                                              to: cal.date(from: DateComponents(year: 2026, month: 9, day: 20))!)
        
        #expect(rangeOccurrences.count == 1)
        #expect(rangeOccurrences.first?.transaction.amount == 200)
    }
}
