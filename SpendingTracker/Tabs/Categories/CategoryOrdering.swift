import Foundation
import SwiftData

/// Centralized helpers for ordering categories consistently across the app
/// (e.g., in CategoriesListView and App Intents / Shortcuts pickers).
enum CategoryOrdering {
    /// Returns categories filtered by optional case-insensitive contains search and sorted by Most Recent usage.
    /// The recency is derived from the latest `Transaction.date` per category.
    static func mostRecent(
        categories: [Category],
        transactions: [Transaction],
        searchText: String? = nil
    ) -> [Category] {
        let trimmed = (searchText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered: [Category]
        if trimmed.isEmpty {
            filtered = categories
        } else {
            let query = trimmed.lowercased()
            filtered = categories.filter { $0.name.lowercased().contains(query) }
        }

        // Build last-used map: categoryID -> latest date
        var lastUsed: [PersistentIdentifier: Date] = [:]
        for txn in transactions {
            if let cat = txn.category {
                let id = cat.persistentModelID
                if let existing = lastUsed[id] {
                    lastUsed[id] = max(existing, txn.date)
                } else {
                    lastUsed[id] = txn.date
                }
            }
        }

        return filtered.sorted { lhs, rhs in
            let lID = lhs.persistentModelID
            let rID = rhs.persistentModelID
            let lDate = lastUsed[lID] ?? .distantPast
            let rDate = lastUsed[rID] ?? .distantPast
            if lDate == rDate {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lDate > rDate
        }
    }

    /// Returns categories filtered by optional case-insensitive contains search and sorted by Most Used (descending count).
    static func mostUsed(
        categories: [Category],
        transactions: [Transaction],
        searchText: String? = nil
    ) -> [Category] {
        let trimmed = (searchText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered: [Category]
        if trimmed.isEmpty {
            filtered = categories
        } else {
            let query = trimmed.lowercased()
            filtered = categories.filter { $0.name.lowercased().contains(query) }
        }

        // Build use-count map: categoryID -> count
        var useCount: [PersistentIdentifier: Int] = [:]
        for txn in transactions {
            if let cat = txn.category {
                let id = cat.persistentModelID
                useCount[id, default: 0] += 1
            }
        }

        return filtered.sorted { lhs, rhs in
            let lID = lhs.persistentModelID
            let rID = rhs.persistentModelID
            let lCount = useCount[lID] ?? 0
            let rCount = useCount[rID] ?? 0
            if lCount == rCount {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lCount > rCount
        }
    }

    /// Convenience: fetch categories and transactions from a ModelContext and return MRU-ordered categories.
    static func fetchMostRecent(from context: ModelContext) throws -> [Category] {
        let cats = try context.fetch(FetchDescriptor<Category>())
        let txns = try context.fetch(FetchDescriptor<Transaction>())
        return mostRecent(categories: cats, transactions: txns)
    }

    /// Convenience: fetch categories and transactions from a ModelContext and return Most-Used ordered categories.
    static func fetchMostUsed(from context: ModelContext) throws -> [Category] {
        let cats = try context.fetch(FetchDescriptor<Category>())
        let txns = try context.fetch(FetchDescriptor<Transaction>())
        return mostUsed(categories: cats, transactions: txns)
    }
}
