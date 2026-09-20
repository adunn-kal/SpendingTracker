//
//  BackupsView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/20/26.
//

import SwiftUI
import CloudKit

struct BackupsView: View {
    @AppStorage("isICloudSyncEnabled") private var isICloudSyncEnabled: Bool = false
    @State private var accountStatus: CKAccountStatus?
    @State private var isLoadingStatus = true
    @State private var statusError: String?

    var body: some View {
        List {
            Section(header: Text("iCloud Sync Status"), footer: Text("Note: Enabling or disabling iCloud synchronization requires restarting Spending Tracker for changes to take effect.")) {
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
                
                Toggle(isOn: $isICloudSyncEnabled) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath.icloud")
                            .foregroundStyle(Color.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("iCloud Synchronization")
                                .font(.body)
                            Text("Automatically backup and sync across devices")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
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
                    Text("Your financial transactions and budgets are stored securely in your personal iCloud account. No one else—including the developer—has access to your data.")
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
                    Text("If you get a new device or lose your phone, signing into your Apple ID will automatically restore all your Spending Tracker data.")
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
        .task {
            await checkStatus()
        }
    }

    private func checkStatus() async {
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
        guard isICloudSyncEnabled else { return "icloud.slash" }
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
        guard isICloudSyncEnabled else { return .secondary }
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
        guard isICloudSyncEnabled else { return "iCloud Sync Disabled" }
        guard let accountStatus else { return "Checking Status" }
        switch accountStatus {
        case .available:
            return "iCloud Connected & Syncing"
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
        guard isICloudSyncEnabled else { return "Turn on toggle below to enable" }
        guard let accountStatus else { return "Contacting Apple iCloud services..." }
        switch accountStatus {
        case .available:
            return "Automatic backups & cross-device sync active"
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
        guard isICloudSyncEnabled else {
            return "iCloud syncing is currently switched off in settings. Your data remains saved locally on this device."
        }
        guard let accountStatus else { return "" }
        switch accountStatus {
        case .available:
            return "All your transactions, categories, and budget goals are stored securely in your private iCloud storage and kept up to date on all your devices."
        case .noAccount:
            return "To enable cloud backups and sync across devices, open System Settings on your device and sign in with your Apple ID."
        case .restricted:
            return "iCloud account access is restricted on this device due to parental controls or enterprise management profiles."
        case .couldNotDetermine, .temporarilyUnavailable:
            return "Unable to determine iCloud status right now. SwiftData will automatically resume syncing when internet connection is re-established."
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
