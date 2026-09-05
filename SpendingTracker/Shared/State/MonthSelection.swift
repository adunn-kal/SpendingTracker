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
}

extension EnvironmentValues {
    @Entry var monthSelection = MonthSelection()
}
