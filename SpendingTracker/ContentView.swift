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
    @State private var selectedTab: AppTab = .spending

    private enum AppTab: CaseIterable {
        case spending
        case transactions
        case budget
        case categories
        case trending
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            SpendingView(onOpenDrawer: { showingDrawer = true })
                .tabItem { Label("Spending", systemImage: "dollarsign.circle") }
                .tag(AppTab.spending)

            TransactionsView(onOpenDrawer: { showingDrawer = true })
                .tabItem { Label("Transactions", systemImage: "list.bullet") }
                .tag(AppTab.transactions)

            BudgetView(onOpenDrawer: { showingDrawer = true })
                .tabItem { Label("Budget", systemImage: "receipt") }
                .tag(AppTab.budget)

            CategoriesView(onOpenDrawer: { showingDrawer = true })
                .tabItem { Label("Categories", systemImage: "tag") }
                .tag(AppTab.categories)

            TrendingView(onOpenDrawer: { showingDrawer = true })
                .tabItem { Label("Trending", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(AppTab.trending)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onEnded(handleTabSwipe)
        )
        .sheet(isPresented: $showingDrawer) {
            NavigationStack {
                DrawerView()
            }
        }
    }

    private func handleTabSwipe(_ value: DragGesture.Value) {
        let horizontal = value.translation.width
        let vertical = value.translation.height

        guard abs(horizontal) > abs(vertical), abs(horizontal) > 50,
              let currentIndex = AppTab.allCases.firstIndex(of: selectedTab) else {
            return
        }

        let nextIndex = horizontal < 0 ? currentIndex + 1 : currentIndex - 1
        guard AppTab.allCases.indices.contains(nextIndex) else { return }

        selectedTab = AppTab.allCases[nextIndex]
    }
}

#Preview {
    let container = PreviewSampleData.makeContainer()
    let monthSelection = MonthSelection()

    return ContentView()
        .environment(\.monthSelection, monthSelection)
        .modelContainer(container)
}
