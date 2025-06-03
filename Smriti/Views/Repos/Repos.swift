//
//  Repos.swift
//  Smriti
//
//  Created by Aarav Gupta on 03/06/25.
//

import SwiftUI

struct Repos: View {
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            NavigationBarView(title: "Repos", scrollOffset: $scrollOffset) {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(0...24, id: \.self) { repo in
                            RepoCard(width: 350, height: 85)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    Repos()
}
