//
//  SpendingTrackerApp.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftUI
import SwiftData

@main
struct SpendingTrackerApp: App {
    private let monthSelection = MonthSelection()

    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            Category.self,
            BudgetGoal.self
        ])
        let isCloudSyncEnabled = UserDefaults.standard.bool(forKey: "isICloudSyncEnabled")
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = isCloudSyncEnabled ? .automatic : .none

        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: cloudKitDatabase
        )

        do {
            return try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            print("Failed to initialize ModelContainer (\(error)). Falling back to local container.")
            let fallbackConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.monthSelection, monthSelection)
        }
        .modelContainer(Self.sharedModelContainer)
    }
}
