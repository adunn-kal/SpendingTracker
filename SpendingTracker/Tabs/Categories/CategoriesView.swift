//
//  CategoriesView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftUI

struct CategoriesView: View {
    var body: some View {
        NavigationStack {
            CategoriesListView()
                .navigationTitle("Categories")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    CategoriesView()
}
