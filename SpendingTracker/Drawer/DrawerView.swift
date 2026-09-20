//
//  DrawerView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftUI

struct DrawerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("Backups") {
                NavigationLink {
                    BackupsView()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("iCloud Backups & Sync")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Automatic cloud backup & status")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "icloud.fill")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }

            Section("Data Management") {
                NavigationLink {
                    ExportTransactionsView()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Export")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Export transactions to CSV format")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                    }
                }

                NavigationLink {
                    ImportTransactionsView()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Import")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Import transactions from CSV file")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
        }
        .navigationTitle("Options")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DrawerView()
    }
}
