//
//  TransactionsView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftUI
import SwiftData

struct TransactionsView: View {
    var onOpenDrawer: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.monthSelection) private var monthSelection

    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Category.name) private var categories: [Category]

    @State private var showingAdd = false
    @State private var editingOccurrence: TransactionOccurrence?
    @State private var searchText = ""
    @State private var selectedCategories: Set<Category> = []
    @State private var includeUncategorized = false

    private var monthOccurrences: [TransactionOccurrence] {
        transactions
            .flatMap { $0.occurrences(in: monthSelection.selectedMonth) }
            .sorted { $0.date > $1.date }
    }

    private var availableCategories: [Category] {
        let categoryIDs = Set(monthOccurrences.compactMap { $0.transaction.category?.persistentModelID })
        return categories.filter { categoryIDs.contains($0.persistentModelID) }
    }

    private var hasUncategorizedTransactions: Bool {
        monthOccurrences.contains { $0.transaction.category == nil }
    }

    private var isFiltering: Bool {
        !selectedCategories.isEmpty || includeUncategorized
    }

    private var filteredOccurrences: [TransactionOccurrence] {
        monthOccurrences.filter { occurrence in
            let matchesSearch: Bool
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                matchesSearch = true
            } else {
                let note = occurrence.transaction.note ?? ""
                matchesSearch = note.localizedCaseInsensitiveContains(searchText)
            }

            let matchesCategory: Bool
            if !isFiltering {
                matchesCategory = true
            } else {
                let category = occurrence.transaction.category
                let categoryMatches = category.map { selectedCategories.contains($0) } ?? false
                let uncategorizedMatches = category == nil && includeUncategorized
                matchesCategory = categoryMatches || uncategorizedMatches
            }

            return matchesSearch && matchesCategory
        }
    }

    private var groupedFilteredOccurrences: [(key: Date, value: [TransactionOccurrence])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredOccurrences) { occurrence in
            calendar.startOfDay(for: occurrence.date)
        }
        return grouped
            .map { (key: $0.key, value: $0.value) }
            .sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthSelector
                searchAndFilterBar

                if monthOccurrences.isEmpty {
                    ContentUnavailableView(
                        "No Transactions",
                        systemImage: "tray",
                        description: Text("No transactions recorded for this month.")
                    )
                } else if filteredOccurrences.isEmpty {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "magnifyingglass",
                        description: Text(emptyStateMessage)
                    )
                } else {
                    List {
                        ForEach(groupedFilteredOccurrences, id: \.key) { group in
                            Section(header: Text(group.key.formatted(.dateTime.year().month().day()))) {
                                ForEach(group.value) { occurrence in
                                    TransactionRow(occurrence: occurrence)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            editingOccurrence = occurrence
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onOpenDrawer?()
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                NavigationStack {
                    TransactionFormView() // Add mode
                }
            }
            .sheet(item: $editingOccurrence) { occurrence in
                NavigationStack {
                    TransactionFormView(
                        transactionToEdit: occurrence.transaction,
                        occurrenceDate: occurrence.date,
                        onDelete: { toDelete in
                            modelContext.delete(toDelete)
                            editingOccurrence = nil
                        }
                    )
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height

                        guard abs(horizontal) > abs(vertical), abs(horizontal) > 50 else { return }

                        if horizontal < 0 {
                            changeMonth(by: 1)   // swipe left → next month
                        } else {
                            changeMonth(by: -1)  // swipe right → previous month
                        }
                    }
            )
        }
    }

    // MARK: - Search + Filter Bar
    private var searchAndFilterBar: some View {
        HStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search notes", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Menu {
                if availableCategories.isEmpty && !hasUncategorizedTransactions {
                    Text("No categories this month")
                } else {
                    ForEach(availableCategories) { category in
                        Button {
                            toggleCategory(category)
                        } label: {
                            HStack {
                                Text(category.name)
                                if selectedCategories.contains(category) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    if hasUncategorizedTransactions {
                        Button {
                            includeUncategorized.toggle()
                        } label: {
                            HStack {
                                Text("Uncategorized")
                                if includeUncategorized {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    if isFiltering {
                        Divider()
                        Button("Clear Filters", role: .destructive) {
                            selectedCategories.removeAll()
                            includeUncategorized = false
                        }
                    }
                }
            } label: {
                Image(systemName: isFiltering ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.title2)
                    .foregroundStyle(isFiltering ? Color.accentColor : Color.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var emptyStateMessage: String {
        if !searchText.isEmpty || isFiltering {
            return "No transactions match your search/filter."
        }
        return "No transactions this month."
    }

    private func toggleCategory(_ category: Category) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
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

    private var addButton: some View {
        Button {
            showingAdd = true
        } label: {
            Image(systemName: "dollarsign")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.accentColor))
                .shadow(radius: 4)
        }
    }
}


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
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
        Transaction(date: now, amount: 40, type: .expense, category: entertainment),
        Transaction(date: now, amount: 40, type: .expense, category: entertainment),
        Transaction(date: now, amount: 40, type: .expense, category: entertainment),
        Transaction(date: now, amount: 40, type: .expense, category: entertainment),
        Transaction(date: now, amount: 40, type: .expense, category: entertainment),
        Transaction(date: now, amount: 40, type: .expense, category: entertainment),
        Transaction(date: now, amount: 40, type: .expense, category: entertainment),
        Transaction(date: now, amount: 40, type: .expense, category: entertainment),
        Transaction(date: now, amount: 40, type: .expense, category: entertainment)
    ]
    
    transactions.forEach { context.insert($0) }
    
    return TransactionsView()
        .modelContainer(container)
}
