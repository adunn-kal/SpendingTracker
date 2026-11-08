//
//  MonthSelectorView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/6/26.
//

import SwiftUI

struct MonthSelectorView: View {
    @Environment(\.monthSelection) private var monthSelection
    @State private var showingPicker = false

    var body: some View {
        HStack {
            Button {
                monthSelection.changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }
            .accessibilityLabel("Previous month")

            Spacer()

            Button {
                showingPicker = true
            } label: {
                HStack(spacing: 4) {
                    Text(monthSelection.selectedMonth.formatted(.dateTime.month(.wide).year()))
                        .font(.headline)
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Select month, current selection is \(monthSelection.selectedMonth.formatted(.dateTime.month(.wide).year()))")
            .accessibilityHint("Opens month and year selector")

            Spacer()

            Button {
                monthSelection.changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
            .accessibilityLabel("Next month")
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .sheet(isPresented: $showingPicker) {
            MonthYearPickerSheet()
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
        }
    }
}

struct MonthYearPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.monthSelection) private var monthSelection

    @State private var selectedMonth: Int = 1
    @State private var selectedYear: Int = 2026

    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: .now)
        let minYear = min(currentYear - 20, selectedYear - 5)
        let maxYear = max(currentYear + 10, selectedYear + 5)
        return Array(minYear...maxYear)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Button {
                    monthSelection.jumpToCurrentMonth()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current Month")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(Date.now.formatted(.dateTime.month(.wide).year()))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if monthSelection.isCurrentMonth {
                            Image(systemName: "checkmark")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .padding(.top, 8)

                HStack(spacing: 0) {
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(Calendar.current.monthSymbols[month - 1]).tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    .onChange(of: selectedMonth) { _, newMonth in
                        monthSelection.setMonth(year: selectedYear, month: newMonth)
                    }

                    Picker("Year", selection: $selectedYear) {
                        ForEach(availableYears, id: \.self) { year in
                            Text(verbatim: "\(year)").tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .onChange(of: selectedYear) { _, newYear in
                        monthSelection.setMonth(year: newYear, month: selectedMonth)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                let calendar = Calendar.current
                selectedMonth = calendar.component(.month, from: monthSelection.selectedMonth)
                selectedYear = calendar.component(.year, from: monthSelection.selectedMonth)
            }
        }
    }
}

#Preview {
    let monthSelection = MonthSelection()
    return MonthSelectorView()
        .environment(\.monthSelection, monthSelection)
}
