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

    private var filteredAndSortedCategories: [Category] {
        switch sortMode {
        case .recent:
            return CategoryOrdering.mostRecent(categories: categories, transactions: transactions, searchText: searchText)
        case .alphabetical:
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let filtered: [Category]
            if trimmed.isEmpty {
                filtered = categories
            } else {
                let query = trimmed.lowercased()
                filtered = categories.filter { $0.name.lowercased().contains(query) }
            }
            return filtered.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .mostUsed:
            return CategoryOrdering.mostUsed(categories: categories, transactions: transactions, searchText: searchText)
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
