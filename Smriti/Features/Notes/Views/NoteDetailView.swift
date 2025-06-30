//
//  NoteDetailView.swift
//  Smriti
//
//  Created by Aarav Gupta on 20/06/25.
//

import SwiftUI

struct NoteDetailView: View {
    let note: SmritiNote
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(note.title)
                    .font(.title)
                    .fontWeight(.bold)
                Text(note.content)
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("Note Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
