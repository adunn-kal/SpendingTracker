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
    
    var selectionMode: Bool = false
    var onSelect: ((Category) -> Void)? = nil
    
    private var sortedCategories: [Category] {
        categories.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                ForEach(sortedCategories) { category in
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
        .sheet(item: $selectedCategory) { category in
            CategoryEditView(category: category)
        }
        .sheet(isPresented: $isAddingNew) {
            CategoryEditView(category: nil)
        }
    }
}
