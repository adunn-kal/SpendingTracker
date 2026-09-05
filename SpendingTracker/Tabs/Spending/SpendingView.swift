//
//  SpendingView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftUI
import SwiftData

struct SpendingView: View {
    @Query(sort: \Transaction.date) private var allTransactions: [Transaction]
    @Environment(\.monthSelection) private var monthSelection
    @State private var showingAddTransaction = false
    
    private var filteredTransactions: [TransactionOccurrence] {
        allTransactions.occurrences(in: monthSelection.selectedMonth)
    }
    
    private var incomeTransactions: [TransactionOccurrence] {
        filteredTransactions.filter { $0.transaction.type == .income }
    }
    
    private var expenseTransactions: [TransactionOccurrence] {
        filteredTransactions.filter { $0.transaction.type == .expense }
    }
    
    private var totalIncome: Double {
        incomeTransactions.reduce(0) { $0 + $1.transaction.amount }
    }
    
    private var totalExpense: Double {
        expenseTransactions.reduce(0) { $0 + $1.transaction.amount }
    }
    
    private var balance: Double {
        totalIncome - totalExpense
    }
    
    private var incomeByCategory: [(name: String, amount: Double)] {
        groupedTotals(for: incomeTransactions)
    }
    
    private var expenseByCategory: [(name: String, amount: Double)] {
        groupedTotals(for: expenseTransactions)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthSelector
                
                incomeExpenseBar
                    .padding(.horizontal)
                    .padding(.top, 12)
                
                ScrollView {
                    VStack(spacing: 16) {
                        categorySection(
                            title: "Income",
                            total: totalIncome,
                            color: .green,
                            categories: incomeByCategory
                        )
                        
                        categorySection(
                            title: "Expense",
                            total: totalExpense,
                            color: .red,
                            categories: expenseByCategory
                        )
                    }
                    .padding(.top, 16)
                }
                
                Divider()
                
                balanceRow
                    .padding()
                
                addTransactionButton
                    .padding(.bottom, 8)
            }
            .navigationTitle("Spending")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
        }
    }
    
    // MARK: - Month Selector
    
    private var monthSelector: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }
            
            Spacer()
            
            Text(monthSelection.selectedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
            
            Spacer()
            
            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func changeMonth(by value: Int) {
        monthSelection.changeMonth(by: value)
    }
    
    // MARK: - Income/Expense Bar
    
    private var incomeExpenseBar: some View {
        GeometryReader { geometry in
            let total = totalIncome + totalExpense
            let incomeWidth = total > 0 ? geometry.size.width * (totalIncome / total) : 0
            let expenseWidth = total > 0 ? geometry.size.width * (totalExpense / total) : 0
            
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.green)
                    .frame(width: incomeWidth)
                
                Rectangle()
                    .fill(Color.red)
                    .frame(width: expenseWidth)
                
                if total == 0 {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(width: geometry.size.width)
                }
            }
        }
        .frame(height: 20)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    // MARK: - Category Section
    
    private func categorySection(
        title: String,
        total: Double,
        color: Color,
        categories: [(name: String, amount: Double)]
    ) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .bold()
                Spacer()
                Text(total, format: .currency(code: "USD"))
                    .font(.headline)
                    .bold()
                    .foregroundStyle(color)
            }
            .padding(.horizontal)
            
            ForEach(categories, id: \.name) { entry in
                HStack {
                    Text(entry.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(entry.amount, format: .currency(code: "USD"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Balance Row
    
    private var balanceRow: some View {
        HStack {
            Text("Balance")
                .font(.title3)
                .bold()
            Spacer()
            Text(balance, format: .currency(code: "USD"))
                .font(.title3)
                .bold()
                .foregroundStyle(balance >= 0 ? .green : .red)
        }
    }
    
    // MARK: - Add Transaction Button
    
    private var addTransactionButton: some View {
        Button {
            showingAddTransaction = true
        } label: {
            Image(systemName: "dollarsign")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.accentColor))
                .shadow(radius: 4)
        }
    }
    
    // MARK: - Grouping Helper
    
    private func groupedTotals(for transactions: [TransactionOccurrence]) -> [(name: String, amount: Double)] {
        let grouped = Dictionary(grouping: transactions) { $0.transaction.category?.name ?? "Uncategorized" }
        return grouped
            .map { (name: $0.key, amount: $0.value.reduce(0) { $0 + $1.transaction.amount }) }
            .sorted { $0.amount > $1.amount }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Transaction.self, Category.self, configurations: config)
    
    let context = container.mainContext
    
    let salary = Category(name: "Salary", icon: "dollarsign.circle", colorHex: "#34C759")
    let selling = Category(name: "Selling", icon: "tag", colorHex: "#30B0C7")
    let groceries = Category(name: "Groceries", icon: "cart", colorHex: "#FF3B30")
    let rent = Category(name: "Rent", icon: "house", colorHex: "#FF9500")
    let entertainment = Category(name: "Entertainment", icon: "tv", colorHex: "#AF52DE")
    
    [salary, selling, groceries, rent, entertainment].forEach { context.insert($0) }
    
    let now = Date.now
    
    let transactions = [
        Transaction(date: now, amount: 3000, type: .income, category: salary),
        Transaction(date: now, amount: 250, type: .income, category: selling),
        Transaction(date: now, amount: 900, type: .expense, category: rent),
        Transaction(date: now, amount: 425.50, type: .expense, category: groceries),
        Transaction(date: now, amount: 120, type: .expense, category: entertainment),
        Transaction(date: now, amount: 60, type: .expense, category: groceries),
        Transaction(date: now, amount: 40, type: .expense, category: entertainment)
    ]
    
    transactions.forEach { context.insert($0) }
    
    return SpendingView()
        .modelContainer(container)
}
