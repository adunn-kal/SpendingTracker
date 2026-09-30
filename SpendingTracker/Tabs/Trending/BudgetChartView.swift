//
//  BudgetChartView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftUI
import Charts
import SwiftData

struct MonthlyBudgetPerformance: Identifiable, Hashable {
    let date: Date
    let monthLabel: String
    let actual: Double
    let target: Double?
    let isIncomeOrSavings: Bool

    var id: Date { date }
    var hasTarget: Bool { target != nil && target! > 0 }

    var isGoalMet: Bool {
        guard let target, target > 0 else { return true }
        return isIncomeOrSavings ? actual >= target : actual <= target
    }
}

struct BudgetGoalSeries: Identifiable, Hashable {
    let id: String
    let type: BudgetGoalType
    let category: Category?
    let categoryTransactionType: TransactionType

    var displayName: String {
        switch type {
        case .category:
            if let catName = category?.name {
                return "\(catName) (\(categoryTransactionType == .income ? "Income" : "Expense"))"
            }
            return "Category Goal"
        case .savings, .income, .expense:
            return type.displayName
        }
    }

    var iconName: String {
        type.iconName
    }
}

struct BudgetChartView: View {
    var monthsWindow: [Date]
    var allTransactions: [Transaction]
    var budgetGoals: [BudgetGoal]

    @State private var selectedSeriesID: String?

    private var availableSeries: [BudgetGoalSeries] {
        var result: [BudgetGoalSeries] = []
        var seenKeys = Set<String>()

        for goal in budgetGoals {
            let key: String
            if goal.type == .category {
                guard let catID = goal.category?.persistentModelID else { continue }
                key = "cat-\(catID)-\(goal.categoryTransactionType.rawValue)"
            } else {
                key = goal.type.rawValue
            }

            if !seenKeys.contains(key) {
                seenKeys.insert(key)
                result.append(
                    BudgetGoalSeries(
                        id: key,
                        type: goal.type,
                        category: goal.category,
                        categoryTransactionType: goal.categoryTransactionType
                    )
                )
            }
        }
        return result
    }

    private var selectedSeries: BudgetGoalSeries? {
        if let id = selectedSeriesID {
            return availableSeries.first(where: { $0.id == id })
        }
        return availableSeries.first
    }

    private var monthlyData: [MonthlyBudgetPerformance] {
        guard let series = selectedSeries else { return [] }
        let calendar = Calendar.current

        return monthsWindow.map { monthStart in
            let occurrences = allTransactions.occurrences(in: monthStart, calendar: calendar)

            // Resolve the active BudgetGoal version for this specific month
            let activeGoal = budgetGoals.filter { goal in
                if goal.type != series.type { return false }
                if series.type == .category {
                    if goal.category?.persistentModelID != series.category?.persistentModelID { return false }
                    if goal.categoryTransactionType != series.categoryTransactionType { return false }
                }
                return goal.effectiveStartDate <= monthStart && (goal.effectiveEndDate == nil || goal.effectiveEndDate! > monthStart)
            }.max(by: { $0.effectiveStartDate < $1.effectiveStartDate })

            let actualAmount: Double
            switch series.type {
            case .savings:
                let inc = occurrences.filter { $0.transaction.type == .income }.reduce(0) { $0 + $1.transaction.amount }
                let exp = occurrences.filter { $0.transaction.type == .expense }.reduce(0) { $0 + $1.transaction.amount }
                actualAmount = inc - exp
            case .income:
                actualAmount = occurrences.filter { $0.transaction.type == .income }.reduce(0) { $0 + $1.transaction.amount }
            case .expense:
                actualAmount = occurrences.filter { $0.transaction.type == .expense }.reduce(0) { $0 + $1.transaction.amount }
            case .category:
                actualAmount = occurrences.filter {
                    $0.transaction.type == series.categoryTransactionType &&
                    $0.transaction.category?.persistentModelID == series.category?.persistentModelID
                }.reduce(0) { $0 + $1.transaction.amount }
            }

            let label = monthsWindow.count > 12 ? monthStart.monthYearAbbrev() : monthStart.monthAbbrev()
            let isIncomeGoal = series.type == .income || series.type == .savings || (series.type == .category && series.categoryTransactionType == .income)

            return MonthlyBudgetPerformance(
                date: monthStart,
                monthLabel: label,
                actual: max(0, actualAmount),
                target: activeGoal?.amount,
                isIncomeOrSavings: isIncomeGoal
            )
        }
    }

    private var monthsMetCount: Int {
        monthlyData.filter(\.isGoalMet).count
    }

    private var targetRangeDescription: String? {
        let targets = monthlyData.compactMap(\.target)
        guard let minT = targets.min(), let maxT = targets.max(), minT != maxT else { return nil }
        return "\(Int(minT).formatted(.currency(code: "USD"))) – \(Int(maxT).formatted(.currency(code: "USD")))"
    }

    private var currentTarget: Double? {
        monthlyData.last?.target ?? monthlyData.compactMap(\.target).last
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if availableSeries.isEmpty {
                    ContentUnavailableView(
                        "No Budget Goals Set",
                        systemImage: "target",
                        description: Text("Create budget goals in the Budget tab to view actual vs target budget trends.")
                    )
                    .padding(.top, 32)
                } else {
                    goalHeader

                    if let series = selectedSeries {
                        summaryCards(for: series)
                        chartView(for: series)
                    }
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            if selectedSeriesID == nil {
                selectedSeriesID = availableSeries.first?.id
            }
        }
    }

    private var goalHeader: some View {
        HStack {
            Menu {
                ForEach(availableSeries) { series in
                    Button {
                        selectedSeriesID = series.id
                    } label: {
                        HStack {
                            Image(systemName: series.iconName)
                            Text(series.displayName)
                            if selectedSeries?.id == series.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if let series = selectedSeries {
                        Image(systemName: series.iconName)
                            .foregroundStyle(Color.accentColor)
                        Text(series.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    } else {
                        Text("Select Budget Goal")
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
        }
        .padding(.horizontal)
    }

    private func summaryCards(for series: BudgetGoalSeries) -> some View {
        HStack(spacing: 12) {
            metricCard(
                title: "Current Target",
                detail: currentTarget != nil ? currentTarget!.formatted(.currency(code: "USD")) : "No Goal",
                subdetail: nil,
                color: .accentColor,
                icon: "target"
            )
            metricCard(
                title: "Months Met",
                detail: "\(monthsMetCount) / \(monthlyData.count)",
                subdetail: nil,
                color: monthsMetCount == monthlyData.count ? .green : .orange,
                icon: "checkmark.seal.fill"
            )
        }
        .padding(.horizontal)
    }

    private func chartView(for series: BudgetGoalSeries) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Chart {
                ForEach(monthlyData) { item in
                    BarMark(
                        x: .value("Month", item.monthLabel),
                        y: .value("Actual", item.actual)
                    )
                    .foregroundStyle(item.isGoalMet ? Color.green.gradient : Color.red.gradient)

                    if let target = item.target {
                        LineMark(
                            x: .value("Month", item.monthLabel),
                            y: .value("Target", target)
                        )
                        .foregroundStyle(Color.primary.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))

                        PointMark(
                            x: .value("Month", item.monthLabel),
                            y: .value("Target", target)
                        )
                        .foregroundStyle(Color.primary)
                    }
                }
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

    private func metricCard(title: String, detail: String, subdetail: String?, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(detail)
                .font(.headline)
                .bold()
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            if let subdetail {
                Text(subdetail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    let container = PreviewSampleData.makeContainer()
    let context = container.mainContext
    let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
    let goals = (try? context.fetch(FetchDescriptor<BudgetGoal>())) ?? []
    let months = (0..<12).compactMap { Calendar.current.date(byAdding: .month, value: -$0, to: .now) }.reversed()

    return BudgetChartView(
        monthsWindow: Array(months),
        allTransactions: transactions,
        budgetGoals: goals
    )
    .modelContainer(container)
}
