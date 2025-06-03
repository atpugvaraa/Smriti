//
//  ContentView.swift
//  Smriti
//
//  Created by Aarav Gupta on 02/06/25.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        TabView {
            Home()
                .tabItem {
                    Image(systemName: "house")
                    
                    Text("Home")
                }
                .tag(0)
            
            Repos()
                .tabItem {
                    Image(systemName: "book.closed.fill")
                    
                    Text("Repos")
                }
                .tag(1)
            
            Notes()
                .tabItem {
                    Image(systemName: "pencil.and.list.clipboard")
                    
                    Text("Notes")
                }
                .tag(2)
            
            Settings()
                .tabItem {
                    Image(systemName: "gear")
                    
                    Text("Settings")
                }
                .tag(3)
        }
    }
}

#Preview {
    RootView {
        ContentView()
    }
}
