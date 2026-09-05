//
//  BudgetView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/6/26.
//

import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.monthSelection) private var monthSelection
    @Query private var allGoals: [BudgetGoal]
    @Query(sort: \Transaction.date) private var allTransactions: [Transaction]
    @State private var showingNewGoal = false
    @State private var editingGoal: BudgetGoal?

    private var selectedMonth: Date {
        monthSelection.selectedMonth
    }

    private var transactionsForSelectedMonth: [TransactionOccurrence] {
        allTransactions.occurrences(in: selectedMonth)
    }

    private var activeGoals: [BudgetGoal] {
        let eligibleGoals = allGoals.filter {
            $0.effectiveStartDate <= selectedMonth
                && ($0.effectiveEndDate == nil || $0.effectiveEndDate! > selectedMonth)
        }

        let overallTypes: [BudgetGoalType] = [.savings, .income, .expense]
        let overallGoals = overallTypes.compactMap { type in
            eligibleGoals
                .filter { $0.type == type }
                .max { $0.effectiveStartDate < $1.effectiveStartDate }
        }

        let categoryGoals = Dictionary(grouping: eligibleGoals.filter { $0.type == .category && $0.category != nil }) {
            "\($0.category!.persistentModelID)-\($0.categoryTransactionType.rawValue)"
        }
        .values
        .compactMap { $0.max { $0.effectiveStartDate < $1.effectiveStartDate } }
        .sorted {
            let categoryOrder = ($0.category?.name ?? "").localizedCaseInsensitiveCompare($1.category?.name ?? "")
            guard categoryOrder == .orderedSame else { return categoryOrder == .orderedAscending }
            return $0.categoryTransactionType.rawValue < $1.categoryTransactionType.rawValue
        }

        return overallGoals + categoryGoals
    }

    private var incomeGoals: [BudgetGoal] {
        activeGoals.filter(\.isIncomeGoal)
    }

    private var expenseGoals: [BudgetGoal] {
        activeGoals.filter { !$0.isIncomeGoal }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthSelector

                Divider()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        if activeGoals.isEmpty {
                            ContentUnavailableView(
                                "No Budget Goals",
                                systemImage: "target",
                                description: Text("Add a goal to track your progress for this month.")
                            )
                            .padding(.top, 48)
                        } else {
                            goalSection(title: "Income", goals: incomeGoals)
                            goalSection(title: "Expenses", goals: expenseGoals)
                        }
                    }
                }

                addGoalButton
                    .padding(.vertical, 16)
            }
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingNewGoal) {
                BudgetGoalEditor(goal: nil, selectedMonth: selectedMonth)
            }
            .sheet(item: $editingGoal) { goal in
                BudgetGoalEditor(goal: goal, selectedMonth: selectedMonth)
            }
        }
    }

    private var monthSelector: some View {
        HStack {
            Button {
                monthSelection.changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)

            Spacer()

            Button {
                monthSelection.changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var addGoalButton: some View {
        Button {
            showingNewGoal = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.accentColor))
                .shadow(radius: 4)
        }
    }

    @ViewBuilder
    private func goalSection(title: String, goals: [BudgetGoal]) -> some View {
        if !goals.isEmpty {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 8)

            ForEach(goals) { goal in
                BudgetGoalRow(goal: goal, actualAmount: actualAmount(for: goal))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingGoal = goal
                    }
                    .padding(.horizontal)

                Divider()
                    .padding(.leading)
            }
        }
    }

    private func actualAmount(for goal: BudgetGoal) -> Double {
        switch goal.type {
        case .savings:
            let income = transactionsForSelectedMonth
                .filter { $0.transaction.type == .income }
                .reduce(0) { $0 + $1.transaction.amount }
            let expenses = transactionsForSelectedMonth
                .filter { $0.transaction.type == .expense }
                .reduce(0) { $0 + $1.transaction.amount }
            return income - expenses
        case .income:
            return transactionsForSelectedMonth
                .filter { $0.transaction.type == .income }
                .reduce(0) { $0 + $1.transaction.amount }
        case .expense:
            return transactionsForSelectedMonth
                .filter { $0.transaction.type == .expense }
                .reduce(0) { $0 + $1.transaction.amount }
        case .category:
            return transactionsForSelectedMonth
                .filter {
                    $0.transaction.type == goal.trackedTransactionType
                        && $0.transaction.category?.persistentModelID == goal.category?.persistentModelID
                }
                .reduce(0) { $0 + $1.transaction.amount }
        }
    }
}

#Preview {
    BudgetView()
        .modelContainer(for: [Transaction.self, Category.self, BudgetGoal.self], inMemory: true)
}
