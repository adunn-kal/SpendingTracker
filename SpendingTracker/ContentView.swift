//
//  ContentView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            SpendingView()
                .tabItem { Label("Spending", systemImage: "dollarsign.circle") }

            TransactionsView()
                .tabItem { Label("Transactions", systemImage: "list.bullet") }

            BudgetView()
                .tabItem { Label("Budget", systemImage: "receipt") }
            
            CategoriesView()
                .tabItem { Label("Categories", systemImage: "tag") }
            
//            TrendingView()
//                .tabItem { Label("Trends", systemImage: "chart.line.uptrend.xyaxis") }
        }
    }
}

#Preview {
    ContentView()
}
