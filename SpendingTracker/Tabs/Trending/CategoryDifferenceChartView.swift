//
//  CategoryDifferenceChartView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftUI
import Charts
import SwiftData

struct MonthlyCategoryNet: Identifiable, Hashable {
    let date: Date
    let monthLabel: String
    let income: Double
    let expense: Double

    var id: Date { date }
    var net: Double { income - expense }
}

struct CategoryDifferenceChartView: View {
    var monthsWindow: [Date]
    var allTransactions: [Transaction]
    var categories: [Category]

    @State private var selectedCategoryID: PersistentIdentifier?

    private var selectedCategory: Category? {
        if let id = selectedCategoryID {
            return categories.first(where: { $0.persistentModelID == id })
        }
        return categories.first
    }

    private var monthlyData: [MonthlyCategoryNet] {
        guard let cat = selectedCategory else { return [] }
        let calendar = Calendar.current
        return monthsWindow.map { monthStart in
            let occurrences = allTransactions.occurrences(in: monthStart, calendar: calendar)
            let catOccurrences = occurrences.filter {
                $0.transaction.category?.persistentModelID == cat.persistentModelID
            }
            let income = catOccurrences
                .filter { $0.transaction.type == .income }
                .reduce(0) { $0 + $1.transaction.amount }
            let expense = catOccurrences
                .filter { $0.transaction.type == .expense }
                .reduce(0) { $0 + $1.transaction.amount }
            let label = monthsWindow.count > 12 ? monthStart.monthYearAbbrev() : monthStart.monthAbbrev()
            return MonthlyCategoryNet(date: monthStart, monthLabel: label, income: income, expense: expense)
        }
    }

    private var totalAmount: Double {
        monthlyData.reduce(0) { $0 + $1.expense + $1.income }
    }

    private var averageMonthlyAmount: Double {
        guard !monthlyData.isEmpty else { return 0 }
        return totalAmount / Double(monthlyData.count)
    }

    private var categoryColor: Color {
        if let hex = selectedCategory?.colorHex {
            return Color(hex: hex)
        }
        return .accentColor
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Category Picker & Summary
                if categories.isEmpty {
                    ContentUnavailableView(
                        "No Categories",
                        systemImage: "tag",
                        description: Text("Create categories in the Categories tab to view category trends.")
                    )
                    .padding(.top, 32)
                } else {
                    categoryHeader

                    if monthlyData.allSatisfy({ $0.income == 0 && $0.expense == 0 }) {
                        ContentUnavailableView(
                            "No Category Data",
                            systemImage: "chart.line.uptrend.xyaxis",
                            description: Text("No transactions recorded for \(selectedCategory?.name ?? "this category") in the selected time range.")
                        )
                        .padding(.top, 32)
                    } else {
                        chartView
                    }
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            if selectedCategoryID == nil {
                selectedCategoryID = categories.first?.persistentModelID
            }
        }
    }

    private var categoryHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Menu {
                    ForEach(categories) { cat in
                        Button {
                            selectedCategoryID = cat.persistentModelID
                        } label: {
                            HStack {
                                Image(systemName: cat.icon)
                                Text(cat.name)
                                if selectedCategory?.persistentModelID == cat.persistentModelID {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if let cat = selectedCategory {
                            Image(systemName: cat.icon)
                                .foregroundStyle(Color(hex: cat.colorHex))
                            Text(cat.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                        } else {
                            Text("Select Category")
                                .font(.headline)
                        }
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total: \(totalAmount, format: .currency(code: "USD"))")
                        .font(.subheadline)
                        .bold()
                    Text("Avg: \(averageMonthlyAmount, format: .currency(code: "USD"))/mo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
        }
    }

    private var chartView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Chart {
                ForEach(monthlyData) { item in
                    let amount = item.expense > 0 ? item.expense : item.income
                    AreaMark(
                        x: .value("Month", item.monthLabel),
                        y: .value("Amount", amount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [categoryColor.opacity(0.35), categoryColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Month", item.monthLabel),
                        y: .value("Amount", amount)
                    )
                    .foregroundStyle(categoryColor)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    PointMark(
                        x: .value("Month", item.monthLabel),
                        y: .value("Amount", amount)
                    )
                    .foregroundStyle(categoryColor)
                }

                RuleMark(y: .value("Average", averageMonthlyAmount))
                    .foregroundStyle(categoryColor.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 280)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }
}

#Preview {
    let container = PreviewSampleData.makeContainer()
    let context = container.mainContext
    let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
    let categories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
    let months = (0..<6).compactMap { Calendar.current.date(byAdding: .month, value: -$0, to: .now) }.reversed()

    return CategoryDifferenceChartView(
        monthsWindow: Array(months),
        allTransactions: transactions,
        categories: categories
    )
    .modelContainer(container)
}
