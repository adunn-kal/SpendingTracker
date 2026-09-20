//
//  DrawerView.swift
//  SpendingTracker
//

import SwiftUI

struct DrawerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("Data") {
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
