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

            TrendingView(onOpenDrawer: { showingDrawer = true })
                .tabItem { Label("Trending", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .sheet(isPresented: $showingDrawer) {
            NavigationStack {
                DrawerView()
            }
        }
    }
}

#Preview {
    let container = PreviewSampleData.makeContainer()
    let monthSelection = MonthSelection()

    return ContentView()
        .environment(\.monthSelection, monthSelection)
        .modelContainer(container)
}
