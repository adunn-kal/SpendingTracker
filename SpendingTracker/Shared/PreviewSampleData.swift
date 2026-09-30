//
//  PreviewSampleData.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/23/26.
//

import Foundation
import SwiftData

@MainActor
enum PreviewSampleData {
    static func makeContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try! ModelContainer(for: Transaction.self, Category.self, BudgetGoal.self, configurations: config)
        let context = container.mainContext

        let salary = Category(name: "Salary", icon: "dollarsign.circle", colorHex: "#34C759")
        let freelance = Category(name: "Freelance", icon: "laptopcomputer", colorHex: "#30B0C7")
        let rent = Category(name: "Rent", icon: "house", colorHex: "#FF9500")
        let groceries = Category(name: "Groceries", icon: "cart", colorHex: "#FF3B30")
        let dining = Category(name: "Dining Out", icon: "fork.knife", colorHex: "#AF52DE")
        let utilities = Category(name: "Utilities", icon: "bolt", colorHex: "#5856D6")
        let subscriptions = Category(name: "Subscriptions", icon: "tv", colorHex: "#007AFF")
        let travel = Category(name: "Travel", icon: "airplane", colorHex: "#10B981")

        let categories = [salary, freelance, rent, groceries, dining, utilities, subscriptions, travel]
        categories.forEach { context.insert($0) }

        let calendar = Calendar.current
        let now = Date.now

        // Generate 18 months of historical data with realistic month-to-month variation
        for monthOffset in 0...18 {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: now) else { continue }

            let year = calendar.component(.year, from: monthDate)
            let month = calendar.component(.month, from: monthDate)

            let date1 = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? monthDate
            let date5 = calendar.date(from: DateComponents(year: year, month: month, day: 5)) ?? monthDate
            let date10 = calendar.date(from: DateComponents(year: year, month: month, day: 10)) ?? monthDate
            let date15 = calendar.date(from: DateComponents(year: year, month: month, day: 15)) ?? monthDate
            let date20 = calendar.date(from: DateComponents(year: year, month: month, day: 20)) ?? monthDate
            let date25 = calendar.date(from: DateComponents(year: year, month: month, day: 25)) ?? monthDate

            // Salary with raise 6 months ago
            let salaryAmount = monthOffset > 6 ? 3400.0 : 3650.0
            context.insert(Transaction(date: date1, amount: salaryAmount, type: .income, note: "Monthly Salary", category: salary))

            // Rent (fixed)
            context.insert(Transaction(date: date1, amount: 1200.0, type: .expense, note: "Apartment Rent", category: rent))

            // Groceries (varying twice a month)
            let grocery1 = 160.0 + Double((monthOffset * 17 + 11) % 55)
            let grocery2 = 145.0 + Double((monthOffset * 23 + 5) % 65)
            context.insert(Transaction(date: date5, amount: grocery1, type: .expense, note: "Supermarket Trip", category: groceries))
            context.insert(Transaction(date: date20, amount: grocery2, type: .expense, note: "Weekly Groceries", category: groceries))

            // Freelance Gig (most months)
            if monthOffset % 3 != 1 {
                let gigAmount = 350.0 + Double((monthOffset * 85) % 450)
                context.insert(Transaction(date: date10, amount: gigAmount, type: .income, note: "Freelance Project", category: freelance))
            }

            // Dining out (fluctuating)
            let diningAmount = 55.0 + Double((monthOffset * 31) % 115)
            context.insert(Transaction(date: date15, amount: diningAmount, type: .expense, note: "Restaurants & Coffee", category: dining))

            // Utilities (seasonal variation)
            let isSummerOrWinter = [6, 7, 8, 12, 1, 2].contains(month)
            let utilityAmount = isSummerOrWinter ? 165.0 : 95.0
            context.insert(Transaction(date: date15, amount: utilityAmount, type: .expense, note: "Electric & Heating", category: utilities))

            // Subscriptions
            context.insert(Transaction(date: date25, amount: 15.99, type: .expense, note: "Streaming Subscriptions", category: subscriptions))

            // Occasional travel expense
            if monthOffset % 4 == 2 {
                let travelAmount = 450.0 + Double((monthOffset * 110) % 350)
                context.insert(Transaction(date: date25, amount: travelAmount, type: .expense, note: "Travel & Flights", category: travel))
            }
        }

        // Add realistic Budget Goals that evolve month-to-month across the 18 months
        let start18m = calendar.date(byAdding: .month, value: -18, to: calendar.startOfMonth(for: now)) ?? now
        let start12m = calendar.date(byAdding: .month, value: -12, to: calendar.startOfMonth(for: now)) ?? now
        let start10m = calendar.date(byAdding: .month, value: -10, to: calendar.startOfMonth(for: now)) ?? now
        let start6m  = calendar.date(byAdding: .month, value: -6,  to: calendar.startOfMonth(for: now)) ?? now

        let goals = [
            // Expense Goal evolution: $2,000 -> $2,400 -> $2,800
            BudgetGoal(type: .expense, amount: 2000.0, effectiveStartDate: start18m, effectiveEndDate: start12m),
            BudgetGoal(type: .expense, amount: 2400.0, effectiveStartDate: start12m, effectiveEndDate: start6m),
            BudgetGoal(type: .expense, amount: 2800.0, effectiveStartDate: start6m, effectiveEndDate: nil),

            // Income Goal evolution: $3,600 -> $4,200
            BudgetGoal(type: .income, amount: 3600.0, effectiveStartDate: start18m, effectiveEndDate: start6m),
            BudgetGoal(type: .income, amount: 4200.0, effectiveStartDate: start6m, effectiveEndDate: nil),

            // Savings Goal (constant)
            BudgetGoal(type: .savings, amount: 1000.0, effectiveStartDate: start18m, effectiveEndDate: nil),

            // Groceries Goal evolution: $350 -> $450
            BudgetGoal(type: .category, amount: 350.0, category: groceries, categoryTransactionType: .expense, effectiveStartDate: start18m, effectiveEndDate: start10m),
            BudgetGoal(type: .category, amount: 450.0, category: groceries, categoryTransactionType: .expense, effectiveStartDate: start10m, effectiveEndDate: nil),

            // Dining Goal evolution: $150 -> $220
            BudgetGoal(type: .category, amount: 150.0, category: dining, categoryTransactionType: .expense, effectiveStartDate: start18m, effectiveEndDate: start6m),
            BudgetGoal(type: .category, amount: 220.0, category: dining, categoryTransactionType: .expense, effectiveStartDate: start6m, effectiveEndDate: nil)
        ]
        goals.forEach { context.insert($0) }

        return container
    }
}
