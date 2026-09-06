//
//  CategoryEditView.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftUI
import SwiftData

struct CategoryEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let category: Category?
    
    @State private var name: String = ""
    @State private var icon: String = "tag"
    @State private var color: Color = .blue
    
    private enum Field: Hashable {
        case name
    }
    @FocusState private var focusedField: Field?
    
    private let iconOptions = [
        // Shopping & Retail
        "tag", "cart", "bag", "basket", "storefront", "creditcard",
        "banknote", "dollarsign.circle", "giftcard", "gift",
        
        // Home & Utilities
        "house", "house.fill", "bolt", "wifi", "flame", "drop",
        "lightbulb", "wrench.and.screwdriver", "hammer", "trash",
        "washer", "sofa",
        
        // Transportation
        "car", "car.fill", "fuelpump", "bus", "tram", "bicycle",
        "airplane", "ferry", "parkingsign", "steeringwheel",
        
        // Food & Dining
        "fork.knife", "cup.and.saucer", "wineglass", "takeoutbag.and.cup.and.straw",
        "birthday.cake", "carrot",
        
        // Entertainment & Leisure
        "tv", "gamecontroller", "film", "music.note", "ticket",
        "popcorn", "party.popper", "theatermasks",
        
        // Health & Wellness
        "heart", "cross.case", "pills", "stethoscope", "figure.walk",
        "figure.run", "dumbbell", "bandage",
        
        // Personal & Family
        "pawprint", "person", "person.2", "figure.2.and.child.holdinghands",
        "teddybear",
        
        // Education & Work
        "graduationcap", "book", "pencil", "briefcase", "printer",
        "laptopcomputer", "building.2",
        
        // Communication & Tech
        "phone", "envelope", "message", "camera", "headphones",
        "applewatch", "iphone",
        
        // Finance & Bills
        "creditcard.and.123", "chart.line.uptrend.xyaxis", "building.columns",
        "doc.text", "receipt", "percent",
        
        // Travel
        "map", "suitcase", "beach.umbrella", "tent", "globe",
        
        // Misc
        "leaf", "star", "sparkles", "questionmark.circle"
    ]
    
    private var isEditing: Bool { category != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category name", text: $name)
                        .focused($focusedField, equals: .name)
                }
                
                Section("Color") {
                    ColorPicker("Chart color", selection: $color, supportsOpacity: false)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(iconOptions, id: \.self) { option in
                            Image(systemName: option)
                                .font(.title2)
                                .foregroundStyle(icon == option ? color : .primary)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle().fill(icon == option ? color.opacity(0.15) : Color(.systemGray6))
                                )
                                .onTapGesture { icon = option }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                if isEditing {
                    Section {
                        Button("Delete Category", role: .destructive) {
                            deleteCategory()
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCategory() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .onAppear {
                if let category {
                    name = category.name
                    icon = category.icon
                    color = Color(hex: category.colorHex)
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private func saveCategory() {
        let hex = color.toHex()
        if let category {
            category.name = name
            category.icon = icon
            category.colorHex = hex
        } else {
            modelContext.insert(Category(name: name, icon: icon, colorHex: hex))
        }
        dismiss()
    }
    
    private func deleteCategory() {
        if let category {
            modelContext.delete(category)
        }
        dismiss()
    }
}
