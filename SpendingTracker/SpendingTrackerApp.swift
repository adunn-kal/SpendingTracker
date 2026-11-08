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

    static let isCloudKitSyncEnabledAtLaunch: Bool = {
        UserDefaults.standard.register(defaults: ["isICloudSyncEnabled": false])
        return UserDefaults.standard.bool(forKey: "isICloudSyncEnabled")
    }()

    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            Category.self,
            BudgetGoal.self
        ])
        
        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: isCloudKitSyncEnabledAtLaunch ? .automatic : .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            fatalError("Could not create the CloudKit ModelContainer: \(error)")
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
