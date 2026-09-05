//  TransactionRow.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftUI

struct TransactionRow: View {
    let occurrence: TransactionOccurrence

    private var transaction: Transaction {
        occurrence.transaction
    }
    
    var body: some View {
        HStack {
            // Icon
            if let icon = transaction.category?.icon, let colorHex = transaction.category?.colorHex {
                Image(systemName: icon)
                    .foregroundStyle(Color(hex: colorHex))
                    .frame(width: 28)
            } else {
                Image(systemName: "questionmark.circle")
                    .foregroundStyle(Color(.systemGray3))
                    .frame(width: 28)
            }

            // Description
            VStack(alignment: .leading, spacing: 2) {
                
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.body)
                }
                else {
                    Text(transaction.category?.name ?? "Uncategorized")
                        .font(.body)
                }
                HStack(spacing: 4) {
                    Text(occurrence.date, format: .dateTime.month().day().year())

                    if transaction.isRecurring {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .accessibilityLabel("Repeating transaction")
                    }
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount
            Text(transaction.amount, format: .currency(code: "USD"))
                .font(.body.weight(.semibold))
                .foregroundColor(transaction.type == .income ? .green : .red)
        }
        .padding(.vertical, 4)
    }
}
