//
//  ExportTransactionsView.swift
//  SpendingTracker
//

import SwiftUI
import SwiftData

struct ExportTransactionsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]

    @State private var isAllTime: Bool = true
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var endDate: Date = .now
    @State private var exportFileURL: URL? = nil

    private var occurrencesToExport: [TransactionOccurrence] {
        if isAllTime {
            let maxDate = allTransactions.map(\.date).max() ?? .now
            let ceiling = max(maxDate, .now)
            return allTransactions.allOccurrences(upTo: ceiling)
        } else {
            return allTransactions.occurrences(from: startDate, to: endDate)
        }
    }

    private var totalIncome: Double {
        occurrencesToExport
            .filter { $0.transaction.type == .income }
            .reduce(0) { $0 + $1.transaction.amount }
    }

    private var totalExpenses: Double {
        occurrencesToExport
            .filter { $0.transaction.type == .expense }
            .reduce(0) { $0 + $1.transaction.amount }
    }

    private var netBalance: Double {
        totalIncome - totalExpenses
    }

    var body: some View {
        Form {
            Section("Date Range") {
                Picker("Range Mode", selection: $isAllTime) {
                    Text("All Time").tag(true)
                    Text("Custom Range").tag(false)
                }
                .pickerStyle(.segmented)

                if !isAllTime {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
            }

            Section("Summary") {
                HStack {
                    Text("Transactions Count")
                    Spacer()
                    Text("\(occurrencesToExport.count)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Total Income")
                    Spacer()
                    Text(totalIncome, format: .currency(code: "USD"))
                        .foregroundStyle(.green)
                }
                HStack {
                    Text("Total Expenses")
                    Spacer()
                    Text(-totalExpenses, format: .currency(code: "USD"))
                        .foregroundStyle(.red)
                }
                HStack {
                    Text("Net Balance")
                    Spacer()
                    Text(netBalance, format: .currency(code: "USD"))
                        .foregroundStyle(netBalance >= 0 ? .green : .red)
                        .bold()
                }
            }

            Section {
                if let url = exportFileURL {
                    ShareLink(item: url, preview: SharePreview("Transactions_Export.csv", image: Image(systemName: "doc.text"))) {
                        Label("Export & Share CSV", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                } else {
                    ContentUnavailableView(
                        "No Transactions",
                        systemImage: "doc.text",
                        description: Text("There are no transactions in the selected date range to export.")
                    )
                }
            }
        }
        .navigationTitle("Export")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateExportFileURL()
        }
        .onChange(of: isAllTime) { _, _ in
            updateExportFileURL()
        }
        .onChange(of: startDate) { _, _ in
            updateExportFileURL()
        }
        .onChange(of: endDate) { _, _ in
            updateExportFileURL()
        }
        .onChange(of: allTransactions) { _, _ in
            updateExportFileURL()
        }
    }

    private func updateExportFileURL() {
        let occurrences = occurrencesToExport
        if occurrences.isEmpty {
            exportFileURL = nil
        } else {
            exportFileURL = generateExportFileURL(for: occurrences)
        }
    }

    private func generateExportFileURL(for occurrences: [TransactionOccurrence]) -> URL? {
        let csvContent = generateCSV(from: occurrences)
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Transactions_Export.csv")
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }

    func generateCSV(from occurrences: [TransactionOccurrence]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"

        var lines = ["Date,Category,Amount,Note"]
        let sortedOccurrences = occurrences.sorted { $0.date < $1.date }

        for occurrence in sortedOccurrences {
            let dateStr = dateFormatter.string(from: occurrence.date)
            let categoryStr = occurrence.transaction.category?.name ?? "Uncategorized"

            let signedAmount: Double
            if occurrence.transaction.type == .expense {
                signedAmount = -abs(occurrence.transaction.amount)
            } else {
                signedAmount = abs(occurrence.transaction.amount)
            }

            let amountStr = String(format: "%.2f", signedAmount)
            let noteStr = occurrence.transaction.note ?? ""

            let escapedCategory = escapeCSVField(categoryStr)
            let escapedNote = escapeCSVField(noteStr)

            lines.append("\(dateStr),\(escapedCategory),\(amountStr),\(escapedNote)")
        }

        return lines.joined(separator: "\n")
    }

    private func escapeCSVField(_ text: String) -> String {
        if text.contains(",") || text.contains("\"") || text.contains("\n") || text.contains("\r") {
            let escaped = text.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return text
    }
}

#Preview {
    NavigationStack {
        ExportTransactionsView()
            .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
    }
}
