//
//  SpendingTrackerTests.swift
//  SpendingTrackerTests
//
//  Created by Alexander Dunn on 9/5/26.
//

import Foundation
import SwiftData
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

    @Test func csvImportParsesExportedFormatCorrectly() throws {
        let importView = ImportTransactionsView()
        let sampleCSV = #"""
        Date,Category,Amount,Note
        09/15/2026,Groceries,-85.50,Supermarket
        09/15/2026,Salary,1500.00,Paycheck
        09/16/2026,"Food, & Dining",-42.00,"Dinner at ""Joe's"""
        """#

        let rows = importView.parseCSV(content: sampleCSV)
        #expect(rows.count == 3)
        #expect(rows[0]["Date"] == "09/15/2026")
        #expect(rows[0]["Category"] == "Groceries")
        #expect(rows[0]["Amount"] == "-85.50")
        #expect(rows[0]["Note"] == "Supermarket")

        #expect(rows[1]["Amount"] == "1500.00")

        #expect(rows[2]["Category"] == "Food, & Dining")
        #expect(rows[2]["Note"] == "Dinner at \"Joe's\"")
    }

    @MainActor
    @Test func csvImportPreviewsAndSavesTransactionsToModelContext() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Transaction.self, Category.self, configurations: config)
        let context = container.mainContext

        let importView = ImportTransactionsView()
        let sampleCSV = """
        Date,Category,Amount,Note
        09/15/2026,Groceries,-85.50,Supermarket
        09/15/2026,Salary,1500.00,Paycheck
        """

        let rows = importView.parseCSV(content: sampleCSV)
        let (items, parseErrors) = importView.parseRowsToPreview(rows)

        #expect(items.count == 2)
        #expect(parseErrors.isEmpty)
        #expect(items[0].type == .expense)
        #expect(items[0].absAmount == 85.50)
        #expect(items[1].type == .income)
        #expect(items[1].absAmount == 1500.00)

        // Save preview items using context
        let (imported, saveErrors) = importView.savePendingItems(items)

        #expect(imported == 2)
        #expect(saveErrors.isEmpty)

        let fetchDescriptor = FetchDescriptor<Transaction>()
        let transactions = try context.fetch(fetchDescriptor)
        #expect(transactions.count == 2)

        let expense = transactions.first(where: { $0.type == .expense })
        #expect(expense?.amount == 85.50)
        #expect(expense?.category?.name == "Groceries")
        #expect(expense?.note == "Supermarket")

        let income = transactions.first(where: { $0.type == .income })
        #expect(income?.amount == 1500.00)
        #expect(income?.category?.name == "Salary")
        #expect(income?.note == "Paycheck")
    }
}
