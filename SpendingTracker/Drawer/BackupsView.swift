//
//  BackupsView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/20/26.
//

import SwiftUI
import CloudKit

struct BackupsView: View {
    @AppStorage("isICloudSyncEnabled") private var isICloudSyncEnabled = false
    @State private var accountStatus: CKAccountStatus?
    @State private var isLoadingStatus = true
    @State private var statusError: String?
    @State private var showsRestartRequiredAlert = false

    private var isCloudKitSyncEnabled: Bool {
        SpendingTrackerApp.isCloudKitSyncEnabledAtLaunch
    }

    private var requiresRestart: Bool {
        isICloudSyncEnabled != isCloudKitSyncEnabled
    }

    var body: some View {
        List {
            Section(header: Text("iCloud Sync Status")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: statusIcon)
                            .font(.title2)
                            .foregroundStyle(statusColor)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(statusTitle)
                                .font(.headline)
                            Text(statusSubtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if isLoadingStatus {
                        ProgressView("Checking iCloud status...")
                            .font(.caption)
                            .padding(.top, 4)
                    } else {
                        Text(statusDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, 4)
                
                Toggle("iCloud Synchronization", isOn: $isICloudSyncEnabled)
                    .onChange(of: isICloudSyncEnabled) { _, _ in
                        showsRestartRequiredAlert = true
                    }

                Text("When enabled, your transactions, categories, and budget goals sync through your private iCloud database. The change takes effect the next time you open the app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("About Cloud Backups") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(.green)
                        Text("Private & Encrypted")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Text("Your financial transactions and budgets are stored securely in your personal iCloud account.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "iphone.and.arrow.forward")
                            .foregroundStyle(.blue)
                        Text("Seamless Recovery")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Text("If you get a new device or lose your phone, signing into your Apple ID will automatically restore your data.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "laptopcomputer.and.iphone")
                            .foregroundStyle(.purple)
                        Text("Automatic Multi-Device Sync")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Text("Changes made on your iPhone, iPad, or Mac will sync seamlessly in the background when connected to the internet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Backups & Sync")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Restart Required", isPresented: $showsRestartRequiredAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your iCloud sync preference will apply the next time you open the app.")
        }
        .task {
            await checkStatus()
        }
    }

    private func checkStatus() async {
        guard isCloudKitSyncEnabled else {
            isLoadingStatus = false
            return
        }

        isLoadingStatus = true
        do {
            let status = try await CKContainer.default().accountStatus()
            await MainActor.run {
                self.accountStatus = status
                self.isLoadingStatus = false
            }
        } catch {
            await MainActor.run {
                self.statusError = error.localizedDescription
                self.isLoadingStatus = false
            }
        }
    }

    private var statusIcon: String {
        if requiresRestart { return "arrow.clockwise.icloud" }
        guard isCloudKitSyncEnabled else { return "icloud.slash" }
        guard statusError == nil else { return "exclamationmark.icloud" }
        guard let accountStatus else { return "icloud" }
        switch accountStatus {
        case .available:
            return "checkmark.icloud.fill"
        case .noAccount:
            return "xmark.icloud"
        case .restricted:
            return "exclamationmark.icloud"
        case .couldNotDetermine, .temporarilyUnavailable:
            return "icloud.slash"
        @unknown default:
            return "icloud"
        }
    }

    private var statusColor: Color {
        if requiresRestart { return .orange }
        guard isCloudKitSyncEnabled else { return .secondary }
        guard statusError == nil else { return .red }
        guard let accountStatus else { return .orange }
        switch accountStatus {
        case .available:
            return .green
        case .noAccount, .restricted:
            return .red
        case .couldNotDetermine, .temporarilyUnavailable:
            return .orange
        @unknown default:
            return .secondary
        }
    }

    private var statusTitle: String {
        if requiresRestart {
            return "Restart Required"
        }

        guard isCloudKitSyncEnabled else {
            return "iCloud Sync Off"
        }

        if statusError != nil {
            return "Unable to Check iCloud"
        }

        guard let accountStatus else { return "Checking Status" }
        switch accountStatus {
        case .available:
            return "iCloud Account Available"
        case .noAccount:
            return "No iCloud Account Signed In"
        case .restricted:
            return "iCloud Access Restricted"
        case .couldNotDetermine:
            return "iCloud Status Unknown"
        case .temporarilyUnavailable:
            return "iCloud Temporarily Unavailable"
        @unknown default:
            return "iCloud Status Unknown"
        }
    }

    private var statusSubtitle: String {
        if requiresRestart {
            return "Your preference will apply when you reopen the app."
        }

        guard isCloudKitSyncEnabled else {
            return "Your data stays on this device."
        }

        if statusError != nil {
            return "Review the error details below."
        }

        guard let accountStatus else { return "Contacting Apple iCloud services..." }
        switch accountStatus {
        case .available:
            return "CloudKit store initialized for automatic sync"
        case .noAccount:
            return "Sign in to iCloud in iOS Settings"
        case .restricted:
            return "Check device restrictions or MDM profiles"
        case .couldNotDetermine, .temporarilyUnavailable:
            return "Check your internet connection"
        @unknown default:
            return ""
        }
    }

    private var statusDescription: String {
        if requiresRestart {
            return "Close and reopen the app to apply your iCloud sync preference."
        }

        guard isCloudKitSyncEnabled else {
            return "iCloud syncing is disabled. Existing iCloud data remains in your private iCloud database, but changes on this device will not synchronize."
        }

        if let statusError {
            return statusError
        }

        guard let accountStatus else { return "" }
        switch accountStatus {
        case .available:
            return "Your transactions, categories, and budget goals are configured to synchronize through your private iCloud database."
        case .noAccount:
            return "To sync across devices, sign in with the same Apple Account on each device."
        case .restricted:
            return "iCloud account access is restricted on this device due to parental controls or enterprise management profiles."
        case .couldNotDetermine, .temporarilyUnavailable:
            return "SwiftData will retry automatically when iCloud becomes available."
        @unknown default:
            return ""
        }
    }
}

#Preview {
    NavigationStack {
        BackupsView()
    }
}
