//
//  CategoriesView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftUI

struct CategoriesView: View {
    var onOpenDrawer: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            CategoriesListView()
                .navigationTitle("Categories")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            onOpenDrawer?()
                        } label: {
                            Image(systemName: "line.3.horizontal")
                        }
                    }
                }
        }
    }
}

#Preview {
    CategoriesView()
}
