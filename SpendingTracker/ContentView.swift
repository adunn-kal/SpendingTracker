//
//  ContentView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showingDrawer = false

    var body: some View {
        TabView {
            SpendingView(onOpenDrawer: { showingDrawer = true })
                .tabItem { Label("Spending", systemImage: "dollarsign.circle") }

            TransactionsView(onOpenDrawer: { showingDrawer = true })
                .tabItem { Label("Transactions", systemImage: "list.bullet") }

            BudgetView(onOpenDrawer: { showingDrawer = true })
                .tabItem { Label("Budget", systemImage: "receipt") }
            
            CategoriesView(onOpenDrawer: { showingDrawer = true })
                .tabItem { Label("Categories", systemImage: "tag") }
        }
        .sheet(isPresented: $showingDrawer) {
            NavigationStack {
                DrawerView()
            }
        }
    }
}

#Preview {
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

    [salary, freelance, rent, groceries, dining, utilities, subscriptions].forEach { context.insert($0) }

    let calendar = Calendar.current
    let now = Date.now

    // Generate transactions spanning current month and 3 previous months
    for monthOffset in 0...3 {
        guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: now) else { continue }
        
        let year = calendar.component(.year, from: monthDate)
        let month = calendar.component(.month, from: monthDate)

        let date1 = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? monthDate
        let date5 = calendar.date(from: DateComponents(year: year, month: month, day: 5)) ?? monthDate
        let date12 = calendar.date(from: DateComponents(year: year, month: month, day: 12)) ?? monthDate
        let date18 = calendar.date(from: DateComponents(year: year, month: month, day: 18)) ?? monthDate
        let date25 = calendar.date(from: DateComponents(year: year, month: month, day: 25)) ?? monthDate

        let sampleTransactions = [
            Transaction(date: date1, amount: 3500.0, type: .income, note: "Monthly Salary", category: salary),
            Transaction(date: date1, amount: 1200.0, type: .expense, note: "Apartment Rent", category: rent),
            Transaction(date: date5, amount: 185.40, type: .expense, note: "Weekly Groceries", category: groceries),
            Transaction(date: date5, amount: 450.0, type: .income, note: "Website Design Gig", category: freelance),
            Transaction(date: date12, amount: 64.50, type: .expense, note: "Dinner with friends", category: dining),
            Transaction(date: date12, amount: 125.0, type: .expense, note: "Electric & Water Bill", category: utilities),
            Transaction(date: date18, amount: 198.20, type: .expense, note: "Supermarket Restock", category: groceries),
            Transaction(date: date18, amount: 15.99, type: .expense, note: "Streaming Service", category: subscriptions),
            Transaction(date: date25, amount: 82.0, type: .expense, note: "Weekend Brunch", category: dining)
        ]

        sampleTransactions.forEach { context.insert($0) }
    }

    // Add budget goals for realistic Budget tab preview
    let startOfThreeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: calendar.startOfMonth(for: now)) ?? now
    let goals = [
        BudgetGoal(type: .income, amount: 4000.0, effectiveStartDate: startOfThreeMonthsAgo),
        BudgetGoal(type: .expense, amount: 2500.0, effectiveStartDate: startOfThreeMonthsAgo),
        BudgetGoal(type: .category, amount: 500.0, category: groceries, categoryTransactionType: .expense, effectiveStartDate: startOfThreeMonthsAgo),
        BudgetGoal(type: .category, amount: 250.0, category: dining, categoryTransactionType: .expense, effectiveStartDate: startOfThreeMonthsAgo)
    ]
    goals.forEach { context.insert($0) }

    let monthSelection = MonthSelection()

    return ContentView()
        .environment(\.monthSelection, monthSelection)
        .modelContainer(container)
}
