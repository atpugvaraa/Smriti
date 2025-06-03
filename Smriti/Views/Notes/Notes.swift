//
//  Notes.swift
//  Smriti
//
//  Created by Aarav Gupta on 03/06/25.
//

import SwiftUI

struct Notes: View {
    @State private var scrollOffset: CGFloat = 0
    
    let columns = [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
    
    var body: some View {
        NavigationStack {
            NavigationBarView(title: "Notes", scrollOffset: $scrollOffset) {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(0..<10, id: \.self) { _ in
                        NotesCard(width: 170, height: 170)
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    Notes()
}
