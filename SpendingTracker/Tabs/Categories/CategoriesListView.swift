//
//  CategoriesListView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftUI
import SwiftData

struct CategoriesListView: View {
    @Query private var categories: [Category]
    @State private var selectedCategory: Category?
    @State private var isAddingNew = false
    @State private var searchText: String = ""
    @State private var sortMode: SortMode = .recent
    @Query private var transactions: [Transaction]
    
    var selectionMode: Bool = false
    var onSelect: ((Category) -> Void)? = nil
    
    enum SortMode: String, CaseIterable, Identifiable {
        case recent = "Most Recent"
        case alphabetical = "A–Z"
        case mostUsed = "Most Used"
        var id: String { rawValue }
    }

    // Build quick lookup maps for last-used date and usage count per category
    private var categoryLastUsed: [PersistentIdentifier: Date] {
        var map: [PersistentIdentifier: Date] = [:]
        for txn in transactions {
            if let cat = txn.category {
                let id: PersistentIdentifier = cat.persistentModelID
                if let existing = map[id] {
                    map[id] = max(existing, txn.date)
                } else {
                    map[id] = txn.date
                }
            }
        }
        return map
    }

    private var categoryUseCount: [PersistentIdentifier: Int] {
        var map: [PersistentIdentifier: Int] = [:]
        for txn in transactions {
            if let cat = txn.category {
                let id: PersistentIdentifier = cat.persistentModelID
                map[id, default: 0] += 1
            }
        }
        return map
    }

    private var filteredAndSortedCategories: [Category] {
        // Filter by search text (case-insensitive, contains)
        let filtered: [Category]
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filtered = categories
        } else {
            let query = searchText.lowercased()
            filtered = categories.filter { $0.name.lowercased().contains(query) }
        }

        // Sort based on selected mode
        switch sortMode {
        case .recent:
            return filtered.sorted { (lhs: Category, rhs: Category) -> Bool in
                let lID: PersistentIdentifier = lhs.persistentModelID
                let rID: PersistentIdentifier = rhs.persistentModelID
                let lDate: Date = categoryLastUsed[lID] ?? .distantPast
                let rDate: Date = categoryLastUsed[rID] ?? .distantPast
                if lDate == rDate {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lDate > rDate
            }
        case .alphabetical:
            return filtered.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .mostUsed:
            return filtered.sorted { (lhs: Category, rhs: Category) -> Bool in
                let lID: PersistentIdentifier = lhs.persistentModelID
                let rID: PersistentIdentifier = rhs.persistentModelID
                let lCount: Int = categoryUseCount[lID] ?? 0
                let rCount: Int = categoryUseCount[rID] ?? 0
                if lCount == rCount {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lCount > rCount
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                ForEach(filteredAndSortedCategories) { category in
                    CategoryRow(category: category)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectionMode {
                                onSelect?(category)
                            } else {
                                selectedCategory = category
                            }
                        }
                }
            }
            .listStyle(.plain)
            
            Button {
                isAddingNew = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.accentColor))
                    .shadow(radius: 4)
            }
            .padding(.bottom, 16)
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Categories")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        sortMode = .recent
                    } label: {
                        HStack {
                            if sortMode == .recent {
                                Image(systemName: "checkmark")
                            }
                            Text("Most Recent")
                        }
                    }
                    Button {
                        sortMode = .alphabetical
                    } label: {
                        HStack {
                            if sortMode == .alphabetical {
                                Image(systemName: "checkmark")
                            }
                            Text("A–Z")
                        }
                    }
                    Button {
                        sortMode = .mostUsed
                    } label: {
                        HStack {
                            if sortMode == .mostUsed {
                                Image(systemName: "checkmark")
                            }
                            Text("Most Used")
                        }
                    }
                } label: {
                    Image(systemName: sortMode == .recent ? "clock.arrow.circlepath" : (sortMode == .alphabetical ? "textformat.abc" : "chart.bar.xaxis"))
                }
                .help("Sort: \(sortMode.rawValue)")
                .accessibilityLabel(Text("Sort: \(sortMode.rawValue)"))
            }
        }
        .sheet(item: $selectedCategory) { category in
            CategoryEditView(category: category)
        }
        .sheet(isPresented: $isAddingNew) {
            CategoryEditView(category: nil)
        }
    }
}

