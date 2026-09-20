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

    func occurrences(from startDate: Date, to endDate: Date, calendar: Calendar = .current) -> [TransactionOccurrence] {
        flatMap { $0.occurrences(from: startDate, to: endDate, calendar: calendar) }
            .sorted { $0.date > $1.date }
    }

    func allOccurrences(upTo maxDate: Date = .now, calendar: Calendar = .current) -> [TransactionOccurrence] {
        flatMap { $0.allOccurrences(upTo: maxDate, calendar: calendar) }
            .sorted { $0.date > $1.date }
    }
}
