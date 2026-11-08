//
//  MonthSelection.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/6/26.
//

import Foundation
import Observation
import SwiftUI

@Observable
final class MonthSelection {
    var selectedMonth = Calendar.current.startOfMonth(for: .now)

    var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: .now, toGranularity: .month)
    }

    func changeMonth(by value: Int) {
        guard let newMonth = Calendar.current.date(
            byAdding: .month,
            value: value,
            to: selectedMonth
        ) else {
            return
        }

        selectedMonth = Calendar.current.startOfMonth(for: newMonth)
    }

    func jumpToCurrentMonth() {
        selectedMonth = Calendar.current.startOfMonth(for: .now)
    }

    func setMonth(year: Int, month: Int) {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        if let newDate = Calendar.current.date(from: components) {
            selectedMonth = Calendar.current.startOfMonth(for: newDate)
        }
    }

    func setMonth(to date: Date) {
        selectedMonth = Calendar.current.startOfMonth(for: date)
    }
}

extension EnvironmentValues {
    @Entry var monthSelection = MonthSelection()
}
