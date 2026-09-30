//
//  IncomeVsSpendingChartView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftUI
import Charts
import SwiftData

struct MonthlyIncomeExpense: Identifiable, Hashable {
    let date: Date
    let monthLabel: String
    let income: Double
    let expense: Double

    var id: Date { date }
    var net: Double { income - expense }
}

struct IncomeVsSpendingChartView: View {
    var monthsWindow: [Date]
    var allTransactions: [Transaction]

    private var monthlyData: [MonthlyIncomeExpense] {
        let calendar = Calendar.current
        return monthsWindow.map { monthStart in
            let occurrences = allTransactions.occurrences(in: monthStart, calendar: calendar)
            let income = occurrences
                .filter { $0.transaction.type == .income }
                .reduce(0) { $0 + $1.transaction.amount }
            let expense = occurrences
                .filter { $0.transaction.type == .expense }
                .reduce(0) { $0 + $1.transaction.amount }
            let label = monthsWindow.count > 12 ? monthStart.monthYearAbbrev() : monthStart.monthAbbrev()
            return MonthlyIncomeExpense(date: monthStart, monthLabel: label, income: income, expense: expense)
        }
    }

    private var totalIncome: Double {
        monthlyData.reduce(0) { $0 + $1.income }
    }

    private var totalExpense: Double {
        monthlyData.reduce(0) { $0 + $1.expense }
    }

    private var netSavings: Double {
        totalIncome - totalExpense
    }

    private var averageMonthlyExpense: Double {
        guard !monthlyData.isEmpty else { return 0 }
        return totalExpense / Double(monthlyData.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Summary Cards
                HStack(spacing: 12) {
                    metricCard(
                        title: "Total Income",
                        amount: totalIncome,
                        color: .green,
                        icon: "arrow.up.circle.fill"
                    )
                    metricCard(
                        title: "Total Spending",
                        amount: totalExpense,
                        color: .red,
                        icon: "arrow.down.circle.fill"
                    )
                    metricCard(
                        title: "Net Savings",
                        amount: netSavings,
                        color: netSavings >= 0 ? .blue : .orange,
                        icon: netSavings >= 0 ? "plus.circle.fill" : "minus.circle.fill"
                    )
                }
                .padding(.horizontal)

                if monthlyData.allSatisfy({ $0.income == 0 && $0.expense == 0 }) {
                    ContentUnavailableView(
                        "No Transactions",
                        systemImage: "chart.bar",
                        description: Text("Add transactions to see income vs spending trends over this period.")
                    )
                    .padding(.top, 32)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Monthly Comparison")
                                .font(.headline)
                            Spacer()
                            Text("Avg spend: \(averageMonthlyExpense, format: .currency(code: "USD"))/mo")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)

                        Chart {
                            ForEach(monthlyData) { item in
                                BarMark(
                                    x: .value("Month", item.monthLabel),
                                    y: .value("Amount", item.income)
                                )
                                .foregroundStyle(Color.green.gradient)
                                .position(by: .value("Type", "Income"))

                                BarMark(
                                    x: .value("Month", item.monthLabel),
                                    y: .value("Amount", item.expense)
                                )
                                .foregroundStyle(Color.red.gradient)
                                .position(by: .value("Type", "Expense"))
                            }

                            RuleMark(y: .value("Avg Expense", averageMonthlyExpense))
                                .foregroundStyle(.blue.opacity(0.4))
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        }
                        .chartLegend(position: .bottom)
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
            .padding(.vertical)
        }
    }

    private func metricCard(title: String, amount: Double, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(amount, format: .currency(code: "USD"))
                .font(.subheadline)
                .bold()
                .minimumScaleFactor(0.8)
                .lineLimit(1)
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
    let months = (0..<6).compactMap { Calendar.current.date(byAdding: .month, value: -$0, to: .now) }.reversed()

    return IncomeVsSpendingChartView(
        monthsWindow: Array(months),
        allTransactions: transactions
    )
    .modelContainer(container)
}
