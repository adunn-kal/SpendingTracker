//
//  CategoryRow.swift
//  SpendingTracker
//
//  Created by Alexander Dunn on 9/5/26.
//

import SwiftUI

struct CategoryRow: View {
    let category: Category
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundStyle(Color(hex: category.colorHex))
                .frame(width: 28)
            
            Text(category.name)
                .font(.body)
            
            Spacer()
            
            Circle()
                .fill(Color(hex: category.colorHex))
                .frame(width: 20, height: 20)
        }
        .padding(.vertical, 4)
    }
}
