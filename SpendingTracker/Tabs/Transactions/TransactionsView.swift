//
//  TransactionsView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Environment(\.monthSelection) private var monthSelection
    @State private var showingAdd = false
    @State private var editingOccurrence: TransactionOccurrence?
    @Environment(\.modelContext) private var modelContext
    
    private var filteredTransactions: [TransactionOccurrence] {
        allTransactions
            .occurrences(in: monthSelection.selectedMonth)
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthSelector
                Spacer()
                Divider()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredTransactions) { occurrence in
                            TransactionRow(occurrence: occurrence)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingOccurrence = occurrence
                                }
                                .padding(.horizontal)
                        }
                        if filteredTransactions.isEmpty {
                            Text("No transactions this month.")
                                .foregroundStyle(.secondary)
                                .padding(.top, 32)
                        }
                    }
                }
                
                addButton
                    .padding(.bottom, 16)
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAdd) {
                NavigationStack {
                    TransactionFormView() // Add mode
                }
            }
            .sheet(item: $editingOccurrence) { occurrence in
                NavigationStack {
                    TransactionFormView(
                        transactionToEdit: occurrence.transaction,
                        occurrenceDate: occurrence.date,
                        onDelete: { toDelete in
                            modelContext.delete(toDelete)
                            editingOccurrence = nil
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Month Selector
    private var monthSelector: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }
            
            Spacer()
            
            Text(monthSelection.selectedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
            
            Spacer()
            
            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func changeMonth(by value: Int) {
        monthSelection.changeMonth(by: value)
    }
    
    private var addButton: some View {
        Button {
            showingAdd = true
        } label: {
            Image(systemName: "dollarsign")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.accentColor))
                .shadow(radius: 4)
        }
    }
}


#Preview {
    TransactionsView()
}
