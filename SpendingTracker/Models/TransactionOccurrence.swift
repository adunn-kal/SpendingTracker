//
//  TransactionOccurrence.swift
//  SpendingTracker
//

import Foundation
import SwiftData

struct TransactionOccurrence: Identifiable {
    let transaction: Transaction
    let date: Date

    var id: String {
        "\(transaction.persistentModelID)-\(date.timeIntervalSinceReferenceDate)"
    }
}

extension Collection where Element == Transaction {
    func occurrences(in month: Date, calendar: Calendar = .current) -> [TransactionOccurrence] {
        flatMap { $0.occurrences(in: month, calendar: calendar) }
    }
}
