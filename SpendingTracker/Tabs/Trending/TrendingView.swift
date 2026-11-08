//
//  TrendingView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftUI
import SwiftData

enum TrendingTimeRange: String, CaseIterable, Identifiable {
    case threeMonths = "3m"
    case sixMonths = "6m"
    case oneYear = "1y"
    case all = "All"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .threeMonths: "3 Months"
        case .sixMonths: "6 Months"
        case .oneYear: "1 Year"
        case .all: "All Time"
        }
    }
}

enum TrendingTab: String, CaseIterable, Identifiable {
    case incomeVsSpending = "Spending"
    case categoryTrends = "Categories"
    case budgetPerformance = "Budgets"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .incomeVsSpending: "chart.bar.fill"
        case .categoryTrends: "tag.fill"
        case .budgetPerformance: "target"
        }
    }
}

struct TrendingView: View {
    @State private var timeRange: TrendingTimeRange = .sixMonths
    @State private var selectedTab: TrendingTab = .incomeVsSpending

    @Query(sort: \Transaction.date) private var allTransactions: [Transaction]
    @Query private var categories: [Category]
    @Query private var budgetGoals: [BudgetGoal]

    var onOpenDrawer: (() -> Void)? = nil

    private var monthsWindow: [Date] {
        let calendar = Calendar.current
        let endMonth = calendar.startOfMonth(for: Date.now)

        let count: Int
        switch timeRange {
        case .threeMonths:
            count = 3
        case .sixMonths:
            count = 6
        case .oneYear:
            count = 12
        case .all:
            guard let minDate = allTransactions.map(\.date).min() else {
                count = 6
                break
            }
            let startMonth = calendar.startOfMonth(for: minDate)
            let components = calendar.dateComponents([.month], from: startMonth, to: endMonth)
            count = max(3, (components.month ?? 0) + 1)
        }

        var dates: [Date] = []
        for i in stride(from: count - 1, through: 0, by: -1) {
            if let d = calendar.date(byAdding: .month, value: -i, to: endMonth) {
                dates.append(calendar.startOfMonth(for: d))
            }
        }
        return dates
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Header Controls
                VStack(spacing: 8) {
                    HStack {
                        Text("Time Range")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("Range", selection: $timeRange) {
                            ForEach(TrendingTimeRange.allCases) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 220)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                switch selectedTab {
                case .incomeVsSpending:
                    IncomeVsSpendingChartView(
                        monthsWindow: monthsWindow,
                        allTransactions: allTransactions
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .categoryTrends:
                    CategoryDifferenceChartView(
                        monthsWindow: monthsWindow,
                        allTransactions: allTransactions,
                        categories: categories
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .budgetPerformance:
                    BudgetChartView(
                        monthsWindow: monthsWindow,
                        allTransactions: allTransactions,
                        budgetGoals: budgetGoals
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Picker("Chart Type", selection: $selectedTab) {
                    ForEach(TrendingTab.allCases) { tab in
                        Label(tab.rawValue, systemImage: tab.iconName).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("Trending")
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

extension Date {
    func monthYearAbbrev(calendar: Calendar = .current) -> String {
        let df = DateFormatter()
        df.locale = Locale.autoupdatingCurrent
        df.setLocalizedDateFormatFromTemplate("MMM yy")
        return df.string(from: self)
    }

    func monthAbbrev(calendar: Calendar = .current) -> String {
        let df = DateFormatter()
        df.locale = Locale.autoupdatingCurrent
        df.setLocalizedDateFormatFromTemplate("MMM")
        return df.string(from: self)
    }
}

#Preview {
    let container = PreviewSampleData.makeContainer()
    return TrendingView()
        .modelContainer(container)
}
