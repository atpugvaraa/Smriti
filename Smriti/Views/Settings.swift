//
//  Settings.swift
//  Smriti
//
//  Created by Aarav Gupta on 03/06/25.
//

import SwiftUI

struct Settings: View {
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationStack {
            NavigationBarView(title: "Settings", scrollOffset: $scrollOffset) {
                Text("Settings")
            }
        }
    }
}

#Preview {
    Settings()
}
