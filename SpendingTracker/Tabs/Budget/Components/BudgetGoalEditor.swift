//
//  BudgetGoalEditor.swift
//  SpendingTracker
//

import SwiftUI
import SwiftData

struct BudgetGoalEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allGoals: [BudgetGoal]

    let goal: BudgetGoal?
    let selectedMonth: Date

    @State private var type: BudgetGoalType = .expense
    @State private var category: Category?
    @State private var categoryTransactionType: TransactionType = .expense
    @State private var amount: Double = 0
    @State private var hasLoadedInitialValues = false
    @State private var showingSaveScopeSelection = false
    @State private var showingDeleteScopeSelection = false

    private enum Field: Hashable {
        case amount
    }

    private enum ChangeScope {
        case thisMonthOnly
        case thisMonthAndFuture
    }

    @FocusState private var focusedField: Field?

    private var canSave: Bool {
        amount > 0 && (type != .category || category != nil)
    }

    private var isEditing: Bool {
        goal != nil
    }

    private var nextMonth: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    Picker("Type", selection: $type) {
                        ForEach(BudgetGoalType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .disabled(isEditing)
                    .onChange(of: type) { _, newType in
                        if newType != .category {
                            category = nil
                        }
                    }

                    if type == .category {
                        NavigationLink {
                            CategoryPickerView { selectedCategory in
                                category = selectedCategory
                            }
                        } label: {
                            HStack {
                                Text("Category")
                                Spacer()
                                if let category {
                                    Image(systemName: category.icon)
                                        .foregroundStyle(Color(hex: category.colorHex))
                                    Text(category.name)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Select")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .disabled(isEditing)

                        Toggle(
                            "Income Goal",
                            isOn: Binding(
                                get: { categoryTransactionType == .income },
                                set: { categoryTransactionType = $0 ? .income : .expense }
                            )
                        )
                    }
                }

                Section("Target") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField(
                            "0.00",
                            value: $amount,
                            format: .number.precision(.fractionLength(2))
                        )
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .amount)
                    }
                }

                if isEditing {
                    Section {
                        Button("Delete Goal", role: .destructive) {
                            focusedField = nil
                            showingDeleteScopeSelection = true
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isEditing ? "Edit Goal" : "New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        focusedField = nil
                        if isEditing {
                            showingSaveScopeSelection = true
                        } else {
                            saveNewGoal()
                        }
                    }
                    .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .onAppear {
                guard !hasLoadedInitialValues, let goal else { return }
                hasLoadedInitialValues = true
                type = goal.type
                category = goal.category
                categoryTransactionType = goal.categoryTransactionType
                amount = goal.amount
            }
            .confirmationDialog(
                "Apply Goal Changes",
                isPresented: $showingSaveScopeSelection,
                titleVisibility: .visible
            ) {
                Button("This Month Only") {
                    saveEditedGoal(for: .thisMonthOnly)
                }
                Button("This Month and Future Months") {
                    saveEditedGoal(for: .thisMonthAndFuture)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose whether this target applies only to \(selectedMonth.formatted(.dateTime.month(.wide).year())) or replaces all later occurrences.")
            }
            .confirmationDialog(
                "Delete Goal",
                isPresented: $showingDeleteScopeSelection,
                titleVisibility: .visible
            ) {
                Button("This Month Only", role: .destructive) {
                    deleteEditedGoal(for: .thisMonthOnly)
                }
                Button("This Month and Future Months", role: .destructive) {
                    deleteEditedGoal(for: .thisMonthAndFuture)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose whether to remove this goal only for \(selectedMonth.formatted(.dateTime.month(.wide).year())) or for all later months too.")
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func hasSameKey(as candidate: BudgetGoal) -> Bool {
        guard candidate.type == type else { return false }
        guard type == .category else { return true }
        return candidate.category?.persistentModelID == category?.persistentModelID
            && candidate.categoryTransactionType == categoryTransactionType
    }

    private func matchingGoals() -> [BudgetGoal] {
        allGoals.filter { hasSameKey(as: $0) }
    }

    /// Ends or removes every version from the selected month forward, preserving prior months.
    private func removeThisAndFutureVersions() {
        for candidate in matchingGoals() {
            if candidate.effectiveStartDate >= selectedMonth {
                modelContext.delete(candidate)
            } else if candidate.effectiveEndDate == nil || candidate.effectiveEndDate! > selectedMonth {
                candidate.effectiveEndDate = selectedMonth
            }
        }
    }

    /// Splits the displayed version so the selected month can differ from the months around it.
    private func preserveVersionsOutsideSelectedMonth(for goal: BudgetGoal) {
        let originalEndDate = goal.effectiveEndDate
        let continuesAfterSelectedMonth = originalEndDate == nil || originalEndDate! > nextMonth

        if goal.effectiveStartDate < selectedMonth {
            goal.effectiveEndDate = selectedMonth

            if continuesAfterSelectedMonth {
                modelContext.insert(
                    BudgetGoal(
                        type: goal.type,
                        amount: goal.amount,
                        category: goal.category,
                        categoryTransactionType: goal.categoryTransactionType,
                        effectiveStartDate: nextMonth,
                        effectiveEndDate: originalEndDate
                    )
                )
            }
        } else if continuesAfterSelectedMonth {
            goal.effectiveStartDate = nextMonth
        } else {
            modelContext.delete(goal)
        }
    }

    private func insertVersion(endDate: Date? = nil) {
        modelContext.insert(
            BudgetGoal(
                type: type,
                amount: amount,
                category: category,
                categoryTransactionType: categoryTransactionType,
                effectiveStartDate: selectedMonth,
                effectiveEndDate: endDate
            )
        )
    }

    private func saveNewGoal() {
        removeThisAndFutureVersions()
        insertVersion()
        dismiss()
    }

    private func saveEditedGoal(for scope: ChangeScope) {
        guard let goal else { return }

        switch scope {
        case .thisMonthOnly:
            preserveVersionsOutsideSelectedMonth(for: goal)
            insertVersion(endDate: nextMonth)
        case .thisMonthAndFuture:
            removeThisAndFutureVersions()
            insertVersion()
        }
        dismiss()
    }

    private func deleteEditedGoal(for scope: ChangeScope) {
        guard let goal else { return }

        switch scope {
        case .thisMonthOnly:
            preserveVersionsOutsideSelectedMonth(for: goal)
        case .thisMonthAndFuture:
            removeThisAndFutureVersions()
        }
        dismiss()
    }
}
