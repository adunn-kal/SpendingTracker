//
//  TransactionsView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Environment(\.monthSelection) private var monthSelection
    @Environment(\.modelContext) private var modelContext

    @State private var showingAdd = false
    @State private var editingOccurrence: TransactionOccurrence?
    @State private var searchText = ""
    @State private var selectedCategories: Set<Category> = []
    @State private var includeUncategorized = false

    // MARK: - Filtering helpers

    private var monthOccurrences: [TransactionOccurrence] {
        allTransactions.occurrences(in: monthSelection.selectedMonth)
    }

    // All categories present among this month's transactions, for the filter menu
    private var availableCategories: [Category] {
        var seen = Set<Category>()
        var result: [Category] = []
        for occurrence in monthOccurrences {
            if let category = occurrence.transaction.category, !seen.contains(category) {
                seen.insert(category)
                result.append(category)
            }
        }
        return result.sorted { $0.name < $1.name }
    }

    // Whether any transaction this month has no category, so we know whether to show the option
    private var hasUncategorizedTransactions: Bool {
        monthOccurrences.contains { $0.transaction.category == nil }
    }

    private var isFiltering: Bool {
        !selectedCategories.isEmpty || includeUncategorized
    }

    private var filteredTransactions: [TransactionOccurrence] {
        var occurrences = monthOccurrences.sorted { $0.date > $1.date }

        // Apply search first across note OR category name
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSearch.isEmpty {
            occurrences = occurrences.filter { occ in
                let noteMatch = occ.transaction.note?.localizedCaseInsensitiveContains(trimmedSearch) ?? false
                let categoryMatch = occ.transaction.category?.name.localizedCaseInsensitiveContains(trimmedSearch) ?? false
                return noteMatch || categoryMatch
            }
        }

        // Then apply category filters
        if isFiltering {
            occurrences = occurrences.filter { occurrence in
                if let category = occurrence.transaction.category {
                    return selectedCategories.contains(category)
                } else {
                    return includeUncategorized
                }
            }
        }

        return occurrences
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthSelector
                searchAndFilterBar
                Divider()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredTransactions) { occurrence in
                            TransactionRow(occurrence: occurrence)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingOccurrence = occurrence
                                }
                                .padding(.horizontal)
                        }
                        if filteredTransactions.isEmpty {
                            Text(emptyStateMessage)
                                .foregroundStyle(.secondary)
                                .padding(.top, 32)
                        }
                    }
                }

                addButton
                    .padding(.bottom, 16)
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
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
    TransactionsView()
}
