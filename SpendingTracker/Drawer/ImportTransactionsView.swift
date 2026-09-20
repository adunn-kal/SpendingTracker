//
//  ImportTransactionsView.swift
//  SpendingTracker
//

import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct ImportPreviewItem: Identifiable {
    let id = UUID()
    let lineNumber: Int
    let date: Date
    let categoryName: String
    let rawAmount: Double
    let type: TransactionType
    let absAmount: Double
    let note: String?
}

struct ImportTransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isImporterPresented = false
    @State private var importResultMessage: String? = nil
    @State private var isProcessingFile = false
    @State private var pendingItems: [ImportPreviewItem] = []
    @State private var parsingErrors: [String] = []
    @State private var isShowingPreview = false

    private var totalIncome: Double {
        pendingItems
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.absAmount }
    }

    private var totalExpenses: Double {
        pendingItems
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.absAmount }
    }

    var body: some View {
        Form {
            if isShowingPreview {
                previewSection
            } else {
                instructionsSection
                selectFileSection
            }

            if isProcessingFile {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Reading CSV file…")
                        Spacer()
                    }
                }
            }

            if let message = importResultMessage, !isShowingPreview {
                Section("Import Summary") {
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(.primary)
                }
            }
        }
        .navigationTitle(isShowingPreview ? "Confirm Import" : "Import")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.commaSeparatedText, .plainText, UTType(filenameExtension: "csv")].compactMap { $0 },
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                processSelectedCSV(from: url)
            case .failure(let error):
                importResultMessage = "Failed to open file: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Sections

    private var instructionsSection: some View {
        Section("CSV Format") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Expected Header Columns:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Date,Category,Amount,Note")
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                
                Text("Amounts should be positive for income and negative for expenses (e.g. -85.50). Dates should be formatted as MM/dd/yyyy.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            .padding(.vertical, 4)
        }
    }

    private var selectFileSection: some View {
        Section {
            Button {
                isImporterPresented = true
            } label: {
                Label("Select CSV File", systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isProcessingFile)
        }
    }

    private var previewSection: some View {
        Group {
            Section("Summary") {
                HStack {
                    Text("Transactions to Import")
                    Spacer()
                    Text("\(pendingItems.count)")
                        .bold()
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
                    Text(totalExpenses, format: .currency(code: "USD"))
                        .foregroundStyle(.red)
                }
            }

            if !parsingErrors.isEmpty {
                Section("Warnings / Skipped Lines") {
                    ForEach(parsingErrors, id: \.self) { error in
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Section("Preview Transactions (\(pendingItems.count))") {
                if pendingItems.isEmpty {
                    Text("No valid transactions found in file.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(pendingItems) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(item.date, format: .dateTime.month().day().year())
                                        .font(.subheadline)
                                        .bold()
                                    Text(item.categoryName)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(Capsule())
                                }
                                if let note = item.note, !note.isEmpty {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(item.rawAmount, format: .currency(code: "USD"))
                                .font(.subheadline)
                                .bold()
                                .foregroundStyle(item.type == .income ? .green : .red)
                        }
                    }
                }
            }

            Section {
                Button {
                    confirmImport()
                } label: {
                    Label("Import \(pendingItems.count) Transaction\(pendingItems.count == 1 ? "" : "s")", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .disabled(pendingItems.isEmpty)

                Button(role: .cancel) {
                    cancelImport()
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Actions

    private func processSelectedCSV(from url: URL) {
        isProcessingFile = true
        importResultMessage = nil
        pendingItems = []
        parsingErrors = []

        Task {
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
                let (items, errors) = parseRowsToPreview(rows)

                isProcessingFile = false
                pendingItems = items
                parsingErrors = errors
                isShowingPreview = true
            } catch {
                isProcessingFile = false
                importResultMessage = "Failed to process file: \(error.localizedDescription)"
            }
        }
    }

    private func confirmImport() {
        let (imported, errors) = savePendingItems(pendingItems)
        var message = "Successfully imported \(imported) transaction\(imported == 1 ? "" : "s")."
        if !errors.isEmpty {
            message += "\n\nErrors:\n" + errors.joined(separator: "\n")
        }
        importResultMessage = message
        pendingItems = []
        parsingErrors = []
        isShowingPreview = false
    }

    private func cancelImport() {
        pendingItems = []
        parsingErrors = []
        isShowingPreview = false
    }

    // MARK: - CSV Parsing & Preview Conversion

    func parseCSV(content: String) -> [[String: String]] {
        let normalized = content.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        var lines = normalized.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        guard !lines.isEmpty else { return [] }

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

    func splitCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var insideQuotes = false
        var iterator = line.makeIterator()
        while let ch = iterator.next() {
            if ch == "\"" {
                if insideQuotes {
                    if let next = iterator.next() {
                        if next == "\"" {
                            current.append("\"")
                        } else if next == "," {
                            insideQuotes = false
                            result.append(current)
                            current = ""
                        } else {
                            insideQuotes = false
                            current.append(next)
                        }
                    } else {
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

    func parseRowsToPreview(_ rows: [[String: String]]) -> (items: [ImportPreviewItem], errors: [String]) {
        var items: [ImportPreviewItem] = []
        var errors: [String] = []

        let df1 = DateFormatter()
        df1.locale = Locale(identifier: "en_US_POSIX")
        df1.dateFormat = "MM/dd/yyyy"

        let df2 = DateFormatter()
        df2.locale = Locale(identifier: "en_US_POSIX")
        df2.dateFormat = "yyyy-MM-dd"

        let df3 = DateFormatter()
        df3.locale = Locale(identifier: "en_US_POSIX")
        df3.dateFormat = "M/d/yyyy"

        for (index, row) in rows.enumerated() {
            let lineNumber = index + 2
            let dateString = row["Date"] ?? row["date"] ?? ""
            let categoryName = row["Category"] ?? row["category"] ?? ""
            let amountString = row["Amount"] ?? row["amount"] ?? ""
            let rawNote = row["Note"] ?? row["note"] ?? ""

            guard let date = df1.date(from: dateString) ?? df3.date(from: dateString) ?? df2.date(from: dateString) else {
                errors.append("Line \(lineNumber): Invalid date \"\(dateString)\"")
                continue
            }
            guard let amount = Double(amountString.replacingOccurrences(of: ",", with: "")) else {
                errors.append("Line \(lineNumber): Invalid amount \"\(amountString)\"")
                continue
            }

            let type: TransactionType = amount >= 0 ? .income : .expense
            let absAmount = abs(amount)
            let trimmedCategory = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
            let displayCategory = (trimmedCategory.isEmpty || trimmedCategory.lowercased() == "uncategorized") ? "Uncategorized" : trimmedCategory
            let noteValue = rawNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : rawNote

            let item = ImportPreviewItem(
                lineNumber: lineNumber,
                date: date,
                categoryName: displayCategory,
                rawAmount: amount,
                type: type,
                absAmount: absAmount,
                note: noteValue
            )
            items.append(item)
        }

        return (items, errors)
    }

    // MARK: - Saving

    func savePendingItems(_ items: [ImportPreviewItem]) -> (imported: Int, errors: [String]) {
        var imported = 0
        var errors: [String] = []

        for item in items {
            do {
                let category: Category?
                if item.categoryName == "Uncategorized" {
                    category = nil
                } else {
                    category = try findOrCreateCategory(named: item.categoryName)
                }

                let transaction = Transaction(
                    date: item.date,
                    amount: item.absAmount,
                    type: item.type,
                    note: item.note,
                    category: category
                )
                modelContext.insert(transaction)
                imported += 1
            } catch {
                errors.append("Line \(item.lineNumber): \(error.localizedDescription)")
            }
        }

        do {
            try modelContext.save()
        } catch {
            errors.append("Failed to save changes: \(error.localizedDescription)")
        }
        return (imported, errors)
    }

    private func findOrCreateCategory(named name: String) throws -> Category {
        let exactFetch = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.name == name }
        )
        if let exact = try modelContext.fetch(exactFetch).first {
            return exact
        }

        var allFetch = FetchDescriptor<Category>()
        allFetch.fetchLimit = 1000
        let all = try modelContext.fetch(allFetch)
        if let ci = all.first(where: { $0.name.compare(name, options: .caseInsensitive) == .orderedSame }) {
            return ci
        }

        let new = Category(name: name, icon: "tag", colorHex: "#007AFF")
        modelContext.insert(new)
        return new
    }
}

#Preview {
    NavigationStack {
        ImportTransactionsView()
            .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
    }
}
