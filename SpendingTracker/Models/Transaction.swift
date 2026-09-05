//
//  Transaction.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftData
import Foundation

@Model
class Transaction {
    var date: Date
    var amount: Double
    var type: TransactionType
    var note: String?
    
    var category: Category?
    
    // Recurrence
    var isRecurring: Bool
    var recurrenceInterval: Int?
    var recurrenceUnit: RecurrenceUnit?
    var recurrenceEndDate: Date?
    /// Identifies all versions of one recurring transaction series.
    var recurrenceSeriesID: UUID?
    /// The first occurrence date this version no longer supplies. Nil means it continues.
    var recurrenceVersionEndDate: Date?
    
    init(
        date: Date = .now,
        amount: Double,
        type: TransactionType,
        note: String? = nil,
        category: Category? = nil,
        isRecurring: Bool = false,
        recurrenceInterval: Int? = nil,
        recurrenceUnit: RecurrenceUnit? = nil,
        recurrenceEndDate: Date? = nil,
        recurrenceSeriesID: UUID? = nil,
        recurrenceVersionEndDate: Date? = nil
    ) {
        self.date = date
        self.amount = amount
        self.type = type
        self.note = note
        self.category = category
        self.isRecurring = isRecurring
        self.recurrenceInterval = recurrenceInterval
        self.recurrenceUnit = recurrenceUnit
        self.recurrenceEndDate = recurrenceEndDate
        self.recurrenceSeriesID = isRecurring ? (recurrenceSeriesID ?? UUID()) : nil
        self.recurrenceVersionEndDate = recurrenceVersionEndDate
    }
}

// MARK: - Transaction Type

enum TransactionType: String, Codable {
    case income
    case expense
}

// MARK: - Recurrence

enum RecurrenceUnit: String, Codable, CaseIterable, Identifiable {
    case day
    case week
    case month
    case year
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .day: "Day(s)"
        case .week: "Week(s)"
        case .month: "Month(s)"
        case .year: "Year(s)"
        }
    }
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
    }
}

// MARK: - Computed helpers

extension Transaction {
    var recurrenceDescription: String? {
        guard isRecurring, let interval = recurrenceInterval, let unit = recurrenceUnit else {
            return nil
        }
        let unitName: String
        switch unit {
        case .day: unitName = interval == 1 ? "day" : "days"
        case .week: unitName = interval == 1 ? "week" : "weeks"
        case .month: unitName = interval == 1 ? "month" : "months"
        case .year: unitName = interval == 1 ? "year" : "years"
        }
        return interval == 1 ? "Every \(unitName)" : "Every \(interval) \(unitName)"
    }
    
    func nextOccurrence(after date: Date) -> Date? {
        guard isRecurring, let interval = recurrenceInterval, let unit = recurrenceUnit else {
            return nil
        }
        return Calendar.current.date(
            byAdding: unit.calendarComponent,
            value: interval,
            to: date
        )
    }

    func occurrences(in month: Date, calendar: Calendar = .current) -> [TransactionOccurrence] {
        let monthStart = calendar.startOfMonth(for: month)
        guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return []
        }

        if !isRecurring {
            return calendar.isDate(date, equalTo: monthStart, toGranularity: .month)
                ? [TransactionOccurrence(transaction: self, date: date)]
                : []
        }

        guard date < monthEnd else { return [] }

        var occurrenceDate = date
        while occurrenceDate < monthStart {
            guard let nextDate = nextOccurrence(after: occurrenceDate) else { return [] }
            occurrenceDate = nextDate
        }

        var occurrences: [TransactionOccurrence] = []
        while occurrenceDate < monthEnd {
            let isWithinSeriesEnd = recurrenceEndDate == nil || occurrenceDate <= recurrenceEndDate!
            let isWithinVersion = recurrenceVersionEndDate == nil || occurrenceDate < recurrenceVersionEndDate!
            if isWithinSeriesEnd && isWithinVersion {
                occurrences.append(TransactionOccurrence(transaction: self, date: occurrenceDate))
            }

            guard let nextDate = nextOccurrence(after: occurrenceDate) else { break }
            occurrenceDate = nextDate
        }
        return occurrences
    }
}
