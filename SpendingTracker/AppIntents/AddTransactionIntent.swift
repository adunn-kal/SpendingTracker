//
//  AddTransactionIntent.swift
//  SpendingTracker
//

import AppIntents
import SwiftData

enum IntentTransactionType: String, AppEnum {
    case expense
    case income

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Transaction Type")
    static var caseDisplayRepresentations: [IntentTransactionType: DisplayRepresentation] = [
        .expense: "Expense",
        .income: "Income"
    ]

    var transactionType: TransactionType {
        self == .expense ? .expense : .income
    }
}

enum IntentRecurrenceUnit: String, AppEnum {
    case day
    case week
    case month
    case year

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Repeat Unit")
    static var caseDisplayRepresentations: [IntentRecurrenceUnit: DisplayRepresentation] = [
        .day: "Day",
        .week: "Week",
        .month: "Month",
        .year: "Year"
    ]

    var recurrenceUnit: RecurrenceUnit {
        switch self {
        case .day: .day
        case .week: .week
        case .month: .month
        case .year: .year
        }
    }
}

struct AddTransactionIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Transaction"
    static var description = IntentDescription("Creates an income or expense transaction in Spending Tracker.")
    static var openAppWhenRun = false

    @Parameter(title: "Type")
    var type: IntentTransactionType

    @Parameter(title: "Date", default: .now)
    var date: Date

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Category")
    var category: TransactionCategoryEntity?

    @Parameter(title: "Repeats", default: false)
    var repeats: Bool

    @Parameter(title: "Repeat Every", default: 1)
    var repeatInterval: Int

    @Parameter(title: "Repeat Unit", default: .month)
    var repeatUnit: IntentRecurrenceUnit

    @Parameter(title: "Repeat End Date")
    var repeatEndDate: Date?

    @Parameter(title: "Description")
    var transactionDescription: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$type) of \(\.$amount)") {
            \.$date
            \.$category
            \.$repeats
            \.$repeatInterval
            \.$repeatUnit
            \.$repeatEndDate
            \.$transactionDescription
        }
    }

    @MainActor
    func perform() throws -> some IntentResult & ProvidesDialog {
        guard amount > 0 else {
            throw AddTransactionIntentError.amountMustBePositive
        }

        let context = SpendingTrackerApp.sharedModelContainer.mainContext
        let selectedCategory = try category.flatMap { entity in
            try context.fetch(FetchDescriptor<Category>()).first {
                String(describing: $0.persistentModelID) == entity.id
            }
        }

        let transaction = Transaction(
            date: date,
            amount: amount,
            type: type.transactionType,
            note: transactionDescription?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty,
            category: selectedCategory,
            isRecurring: repeats,
            recurrenceInterval: repeats ? max(1, repeatInterval) : nil,
            recurrenceUnit: repeats ? repeatUnit.recurrenceUnit : nil,
            recurrenceEndDate: repeats ? repeatEndDate : nil
        )
        context.insert(transaction)
        try context.save()

        let formattedAmount = amount.formatted(.currency(code: "USD"))
        let typeName = type == .expense ? "expense" : "income"
        return .result(dialog: "Added a \(formattedAmount) \(typeName) transaction.")
    }
}

private enum AddTransactionIntentError: LocalizedError {
    case amountMustBePositive

    var errorDescription: String? {
        "The transaction amount must be greater than zero."
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
