//
//  TransactionCategoryEntity.swift
//  SpendingTracker
//

import AppIntents
import SwiftData

/// A category the user has created in Spending Tracker, made available to Siri and Shortcuts.
struct TransactionCategoryEntity: AppEntity, Identifiable {
    let id: String
    let name: String
    let icon: String

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Category")
    static var defaultQuery = TransactionCategoryQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: name),
            image: .init(systemName: icon)
        )
    }

    init(category: Category) {
        id = String(describing: category.persistentModelID)
        name = category.name
        icon = category.icon
    }
}

struct TransactionCategoryQuery: EntityQuery {
    func entities(for identifiers: [TransactionCategoryEntity.ID]) async throws -> [TransactionCategoryEntity] {
        try await MainActor.run {
            try fetchCategories().filter { identifiers.contains($0.id) }
        }
    }

    func suggestedEntities() async throws -> [TransactionCategoryEntity] {
        try await MainActor.run {
            try fetchCategories()
        }
    }

    @MainActor
    private func fetchCategories() throws -> [TransactionCategoryEntity] {
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\Category.name)])
        return try SpendingTrackerApp.sharedModelContainer.mainContext
            .fetch(descriptor)
            .map(TransactionCategoryEntity.init(category:))
    }
}
