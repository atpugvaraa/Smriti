//
//  Home.swift
//  Smriti
//
//  Created by Aarav Gupta on 03/06/25.
//

import SwiftUI

struct Home: View {
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            NavigationBarView(title: "Smriti", scrollOffset: $scrollOffset) {
                Text("Home")
            }
        }
    }
}

#Preview {
    Home()
}
