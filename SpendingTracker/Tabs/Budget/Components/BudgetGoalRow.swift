//
//  BudgetGoalRow.swift
//  SpendingTracker
//

import SwiftUI

struct BudgetGoalRow: View {
    let goal: BudgetGoal
    let actualAmount: Double

    private var progress: Double {
        guard goal.amount > 0 else { return 0 }
        return actualAmount / goal.amount
    }

    private var progressColor: Color {
        if progress == 1 { return .orange }

        if goal.isIncomeGoal {
            return progress > 1 ? .green : .red
        }

        if progress < 1 { return .green }
        return .red
    }

    private var title: String {
        goal.type == .category ? goal.category?.name ?? "Deleted Category" : goal.type.displayName
    }

    private var iconColor: Color {
        switch goal.type {
        case .income, .savings:
            return Color.green
        case .expense:
            return Color.red
        case .category:
            guard let category = goal.category else { return .primary }
            return Color(hex: category.colorHex)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: goal.type == .category ? goal.category?.icon ?? goal.type.iconName : goal.type.iconName)
                    .foregroundStyle(iconColor)

                Text(title)

                Spacer()

                Text(actualAmount, format: .currency(code: "USD"))
                    .fontWeight(.semibold)
                Text("of")
                    .foregroundStyle(.secondary)
                Text(goal.amount, format: .currency(code: "USD"))
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)

            ProgressView(value: min(max(progress, 0), 1))
                .tint(progressColor)
        }
        .padding(.vertical, 4)
    }
}
