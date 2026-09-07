//
//  ImportingView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/7/26.
//

import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct ImportingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isImporterPresented = false
    @State private var importResultMessage: String? = nil
    @State private var isImporting = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Import Transactions from CSV")
                .font(.title2)
                .bold()

            Text("Expected columns: Date, Category, Amount, Note")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                isImporterPresented = true
            } label: {
                Label("Choose CSV File", systemImage: "tray.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .disabled(isImporting)

            if isImporting {
                ProgressView("Importing…")
            }

            if let message = importResultMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .padding()
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [UTType.commaSeparatedText, UTType.plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importCSV(from: url)
            case .failure(let error):
                importResultMessage = "Failed to open file: \(error.localizedDescription)"
            }
        }
    }

    private func importCSV(from url: URL) {
        isImporting = true
        importResultMessage = nil

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let shouldStopAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    if shouldStopAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                let data = try Data(contentsOf: url)
                guard let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16) else {
                    throw NSError(domain: "Import", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported file encoding. Use UTF-8."])
                }

                let rows = parseCSV(content: content)

                DispatchQueue.main.async {
                    let (imported, skipped, errors) = saveRows(rows)
                    isImporting = false
                    var message = "Imported \(imported) transactions."
                    if skipped > 0 { message += " Skipped \(skipped)." }
                    if !errors.isEmpty { message += " Errors: \(errors.joined(separator: "; "))." }
                    importResultMessage = message
                }
            } catch {
                DispatchQueue.main.async {
                    isImporting = false
                    importResultMessage = "Import failed: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - CSV Parsing

    private func parseCSV(content: String) -> [[String: String]] {
        // Normalize newlines
        let normalized = content.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        var lines = normalized.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        guard !lines.isEmpty else { return [] }

        // Determine headers (trim whitespace)
        let headerLine = lines.removeFirst()
        let headers = splitCSVLine(headerLine).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var rows: [[String: String]] = []
        rows.reserveCapacity(lines.count)
        for line in lines where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            let values = splitCSVLine(line)
            var dict: [String: String] = [:]
            for (i, header) in headers.enumerated() {
                if i < values.count {
                    dict[header] = values[i].trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    dict[header] = ""
                }
            }
            rows.append(dict)
        }
        return rows
    }

    private func splitCSVLine(_ line: String) -> [String] {
        // Handles simple CSV with optional quoted fields and commas inside quotes
        var result: [String] = []
        var current = ""
        var insideQuotes = false
        var iterator = line.makeIterator()
        while let ch = iterator.next() {
            if ch == "\"" { // quote
                if insideQuotes {
                    // Lookahead for escaped quote
                    if let next = iterator.next() {
                        if next == "\"" { // escaped quote
                            current.append("\"")
                        } else if next == "," { // end of quoted field
                            insideQuotes = false
                            result.append(current)
                            current = ""
                        } else {
                            // end quote, continue with next char
                            insideQuotes = false
                            current.append(next)
                        }
                    } else {
                        // closing quote at end of line
                        insideQuotes = false
                    }
                } else {
                    insideQuotes = true
                }
            } else if ch == "," && !insideQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(ch)
            }
        }
        result.append(current)
        return result
    }

    // MARK: - Saving

    private func saveRows(_ rows: [[String: String]]) -> (imported: Int, skipped: Int, errors: [String]) {
        var imported = 0
        var skipped = 0
        var errors: [String] = []

        // Date formatter matching sample: 09/17/2026
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "MM/dd/yyyy"

        for (index, row) in rows.enumerated() {
            let lineNumber = index + 2 // +1 for headers, +1 for 1-based line numbers
            let dateString = row["Date"] ?? row["date"] ?? ""
            let categoryName = row["Category"] ?? row["category"] ?? ""
            let amountString = row["Amount"] ?? row["amount"] ?? ""
            let note = row["Note"] ?? row["note"] ?? ""

            guard let date = df.date(from: dateString) else {
                skipped += 1
                errors.append("Line \(lineNumber): Invalid date \"\(dateString)\"")
                continue
            }
            guard let amount = Double(amountString.replacingOccurrences(of: ",", with: "")) else {
                skipped += 1
                errors.append("Line \(lineNumber): Invalid amount \"\(amountString)\"")
                continue
            }
            guard !categoryName.isEmpty else {
                skipped += 1
                errors.append("Line \(lineNumber): Missing category")
                continue
            }

            do {
                try createTransaction(date: date, categoryName: categoryName, amount: amount, note: note)
                imported += 1
            } catch {
                skipped += 1
                errors.append("Line \(lineNumber): \(error.localizedDescription)")
            }
        }

        // Save all inserts in one batch
         do {
             try modelContext.save()
         } catch {
             errors.append("Failed to save changes: \(error.localizedDescription)")
         }
         return (imported, skipped, errors)
    }

    private func createTransaction(date: Date, categoryName: String, amount: Double, note: String) throws {
        // Find or create category by name (case-insensitive)
        let category = try findOrCreateCategory(named: categoryName)
        
        let type = amount >= 0 ? TransactionType.income : TransactionType.expense
        let normalizedAmount = abs(amount)

        // Create a Transaction model. Assumes a Transaction @Model exists with properties: date: Date, amount: Double, note: String, category: Category?
        let transaction = Transaction(date: date, amount: normalizedAmount, type: type, note: note, category: category)
        modelContext.insert(transaction)
    }

    private func findOrCreateCategory(named name: String) throws -> Category {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        // First try exact match predicate (supported by SwiftData's predicate macro)
        let exactFetch = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.name == trimmed }
        )
        if let exact = try modelContext.fetch(exactFetch).first {
            return exact
        }

        // Fall back to case-insensitive match by fetching a small set and comparing in Swift
        var allFetch = FetchDescriptor<Category>()
        allFetch.fetchLimit = 1000 // reasonable cap; adjust as needed
        let all = try modelContext.fetch(allFetch)
        if let ci = all.first(where: { $0.name.compare(trimmed, options: .caseInsensitive) == .orderedSame }) {
            return ci
        }

        // Create with basic defaults for icon/color if not present
        let new = Category(name: trimmed, icon: "folder", colorHex: "#9AA0A6")
        modelContext.insert(new)
        try modelContext.save()
        return new
    }
}

#Preview {
    ImportingView()
}
