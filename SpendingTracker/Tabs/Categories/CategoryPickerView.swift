//
//  CategoryPickerView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftUI

struct CategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (Category) -> Void
    
    var body: some View {
        CategoriesListView(selectionMode: true) { category in
            onSelect(category)
            dismiss()
        }
        .navigationTitle("Select Category")
        .navigationBarTitleDisplayMode(.inline)
    }
}
