//
//  TransactionFormView.swift
//  SpendingTracker
//

import SwiftUI
import SwiftData

struct TransactionFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var transactionToEdit: Transaction?
    var occurrenceDate: Date? = nil
    var onSave: ((Transaction) -> Void)? = nil
    var onDelete: ((Transaction) -> Void)? = nil

    @State private var type: TransactionType = .expense
    @State private var date: Date = .now
    @State private var amount: Double = 0
    @State private var selectedCategory: Category?
    @State private var isRecurring = false
    @State private var recurrenceInterval = 1
    @State private var recurrenceUnit: RecurrenceUnit = .month
    @State private var hasEndDate = false
    @State private var recurrenceEndDate: Date = .now
    @State private var note = ""
    @State private var hasLoadedInitialValues = false
    @State private var showingSaveScopeSelection = false
    @State private var showingDeleteScopeSelection = false

    private enum Field: Hashable { case amount, note }
    private enum ChangeScope { case thisOccurrenceOnly, thisAndFutureOccurrences }
    @FocusState private var focusedField: Field?

    private var tintColor: Color { type == .income ? .green : .red }
    private var canSave: Bool { amount > 0 }
    private var isEditing: Bool { transactionToEdit != nil }
    private var isEditingRecurring: Bool { transactionToEdit?.isRecurring == true && occurrenceDate != nil }

    var body: some View {
        Form {
            Section {
                Picker("Type", selection: $type) {
                    Text("Expense").tag(TransactionType.expense)
                    Text("Income").tag(TransactionType.income)
                }
                .pickerStyle(.segmented)
            }

            Section {
                DatePicker("Date", selection: $date, displayedComponents: .date)

                HStack {
                    Text("Amount")
                    Spacer()
                    Text("$").foregroundStyle(.secondary)
                    TextField("0.00", value: $amount, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(tintColor)
                        .focused($focusedField, equals: .amount)
                }

                NavigationLink {
                    CategoryPickerView { selectedCategory = $0 }
                } label: {
                    HStack {
                        Text("Category")
                        Spacer()
                        if let selectedCategory {
                            Image(systemName: selectedCategory.icon)
                                .foregroundStyle(Color(hex: selectedCategory.colorHex))
                            Text(selectedCategory.name).foregroundStyle(.secondary)
                        } else {
                            Text("Select").foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Toggle("Repeating", isOn: $isRecurring)
                    .tint(tintColor)
                    .onChange(of: isRecurring) { _, newValue in
                        if !newValue {
                            recurrenceInterval = 1
                            recurrenceUnit = .month
                            hasEndDate = false
                            recurrenceEndDate = .now
                        }
                    }

                if isRecurring {
                    HStack {
                        Text("Every")
                        Spacer()
                        Stepper(value: $recurrenceInterval, in: 1...99) {
                            Text("\(recurrenceInterval)").frame(minWidth: 24)
                        }
                    }
                    Picker("Unit", selection: $recurrenceUnit) {
                        ForEach(RecurrenceUnit.allCases) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    Toggle("End Date", isOn: $hasEndDate).tint(tintColor)
                    if hasEndDate {
                        DatePicker("Ends", selection: $recurrenceEndDate, in: date..., displayedComponents: .date)
                    }
                }
            }

            Section("Description") {
                TextField("Add a note", text: $note, axis: .vertical)
                    .lineLimit(3...6)
                    .focused($focusedField, equals: .note)
            }

            if let transactionToEdit, onDelete != nil {
                Section {
                    Button("Delete Transaction", role: .destructive) {
                        focusedField = nil
                        if transactionToEdit.isRecurring, occurrenceDate != nil {
                            showingDeleteScopeSelection = true
                        } else {
                            deleteOneTimeTransaction(transactionToEdit)
                        }
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(isEditing ? "Edit Transaction" : "Add Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    focusedField = nil
                    if isEditingRecurring {
                        showingSaveScopeSelection = true
                    } else {
                        saveStandardTransaction()
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
            guard !hasLoadedInitialValues else { return }
            hasLoadedInitialValues = true
            guard let transactionToEdit else { return }
            type = transactionToEdit.type
            date = occurrenceDate ?? transactionToEdit.date
            amount = transactionToEdit.amount
            selectedCategory = transactionToEdit.category
            isRecurring = transactionToEdit.isRecurring
            recurrenceInterval = transactionToEdit.recurrenceInterval ?? 1
            recurrenceUnit = transactionToEdit.recurrenceUnit ?? .month
            hasEndDate = transactionToEdit.recurrenceEndDate != nil
            recurrenceEndDate = transactionToEdit.recurrenceEndDate ?? .now
            note = transactionToEdit.note ?? ""
        }
        .confirmationDialog("Apply Transaction Changes", isPresented: $showingSaveScopeSelection, titleVisibility: .visible) {
            Button("This Occurrence Only") { saveRecurringEdit(for: .thisOccurrenceOnly) }
            Button("This and Future Occurrences") { saveRecurringEdit(for: .thisAndFutureOccurrences) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose whether these changes apply only to this occurrence or to this and all future occurrences.")
        }
        .confirmationDialog("Delete Transaction", isPresented: $showingDeleteScopeSelection, titleVisibility: .visible) {
            Button("This Occurrence Only", role: .destructive) { deleteRecurring(for: .thisOccurrenceOnly) }
            Button("This and Future Occurrences", role: .destructive) { deleteRecurring(for: .thisAndFutureOccurrences) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose whether to delete only this occurrence or this and all future occurrences.")
        }
        .presentationDetents([.large])
    }

    private func makeTransaction(isRecurring: Bool, seriesID: UUID? = nil, versionEndDate: Date? = nil) -> Transaction {
        Transaction(
            date: date,
            amount: amount,
            type: type,
            note: note.isEmpty ? nil : note,
            category: selectedCategory,
            isRecurring: isRecurring,
            recurrenceInterval: isRecurring ? recurrenceInterval : nil,
            recurrenceUnit: isRecurring ? recurrenceUnit : nil,
            recurrenceEndDate: (isRecurring && hasEndDate) ? recurrenceEndDate : nil,
            recurrenceSeriesID: seriesID,
            recurrenceVersionEndDate: versionEndDate
        )
    }

    private func saveStandardTransaction() {
        if let transactionToEdit {
            transactionToEdit.date = date
            transactionToEdit.amount = amount
            transactionToEdit.type = type
            transactionToEdit.note = note.isEmpty ? nil : note
            transactionToEdit.category = selectedCategory
            transactionToEdit.isRecurring = isRecurring
            transactionToEdit.recurrenceInterval = isRecurring ? recurrenceInterval : nil
            transactionToEdit.recurrenceUnit = isRecurring ? recurrenceUnit : nil
            transactionToEdit.recurrenceEndDate = (isRecurring && hasEndDate) ? recurrenceEndDate : nil
            transactionToEdit.recurrenceSeriesID = isRecurring ? (transactionToEdit.recurrenceSeriesID ?? UUID()) : nil
            transactionToEdit.recurrenceVersionEndDate = nil
            onSave?(transactionToEdit)
        } else {
            let transaction = makeTransaction(isRecurring: isRecurring)
            modelContext.insert(transaction)
            onSave?(transaction)
        }
        dismiss()
    }

    private func nextOccurrence(after occurrence: Date, for transaction: Transaction) -> Date? {
        transaction.nextOccurrence(after: occurrence)
    }

    private func splitSeriesAroundSelectedOccurrence(_ transaction: Transaction, occurrence: Date) {
        let oldVersionEnd = transaction.recurrenceVersionEndDate
        let oldSeriesEnd = transaction.recurrenceEndDate
        let seriesID = transaction.recurrenceSeriesID ?? UUID()
        guard let nextDate = nextOccurrence(after: occurrence, for: transaction) else { return }

        if transaction.date < occurrence {
            transaction.recurrenceVersionEndDate = occurrence
        } else {
            modelContext.delete(transaction)
        }

        let continuesAfter = (oldVersionEnd == nil || nextDate < oldVersionEnd!)
            && (oldSeriesEnd == nil || nextDate <= oldSeriesEnd!)
        if continuesAfter {
            modelContext.insert(
                Transaction(
                    date: nextDate,
                    amount: transaction.amount,
                    type: transaction.type,
                    note: transaction.note,
                    category: transaction.category,
                    isRecurring: true,
                    recurrenceInterval: transaction.recurrenceInterval,
                    recurrenceUnit: transaction.recurrenceUnit,
                    recurrenceEndDate: oldSeriesEnd,
                    recurrenceSeriesID: seriesID,
                    recurrenceVersionEndDate: oldVersionEnd
                )
            )
        }
    }

    private func endSeriesFromSelectedOccurrence(_ transaction: Transaction, occurrence: Date) {
        let seriesID = transaction.recurrenceSeriesID
        let matchingVersions = seriesID.map { id in
            allTransactionsInSeries(id)
        } ?? [transaction]

        for version in matchingVersions {
            if version.date >= occurrence {
                modelContext.delete(version)
            } else if version.recurrenceVersionEndDate == nil || version.recurrenceVersionEndDate! > occurrence {
                version.recurrenceVersionEndDate = occurrence
            }
        }
    }

    private func allTransactionsInSeries(_ seriesID: UUID) -> [Transaction] {
        // SwiftData models currently in this context; the edit source retains all versions through its relationship-free identity.
        // The query is performed by the list views, while this loop only needs versions loaded in the context.
        (try? modelContext.fetch(FetchDescriptor<Transaction>()))?.filter { $0.recurrenceSeriesID == seriesID } ?? []
    }

    private func saveRecurringEdit(for scope: ChangeScope) {
        guard let transaction = transactionToEdit, let occurrence = occurrenceDate else { return }
        let seriesID = transaction.recurrenceSeriesID ?? UUID()
        switch scope {
        case .thisOccurrenceOnly:
            splitSeriesAroundSelectedOccurrence(transaction, occurrence: occurrence)
            modelContext.insert(makeTransaction(isRecurring: false))
        case .thisAndFutureOccurrences:
            endSeriesFromSelectedOccurrence(transaction, occurrence: occurrence)
            modelContext.insert(makeTransaction(isRecurring: isRecurring, seriesID: isRecurring ? seriesID : nil))
        }
        dismiss()
    }

    private func deleteRecurring(for scope: ChangeScope) {
        guard let transaction = transactionToEdit, let occurrence = occurrenceDate else { return }
        switch scope {
        case .thisOccurrenceOnly:
            splitSeriesAroundSelectedOccurrence(transaction, occurrence: occurrence)
        case .thisAndFutureOccurrences:
            endSeriesFromSelectedOccurrence(transaction, occurrence: occurrence)
        }
        dismiss()
    }

    private func deleteOneTimeTransaction(_ transaction: Transaction) {
        if let onDelete {
            onDelete(transaction)
        } else {
            modelContext.delete(transaction)
        }
        dismiss()
    }
}
