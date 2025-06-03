//
//  SmritiApp.swift
//  Smriti
//
//  Created by Aarav Gupta on 02/06/25.
//

import SwiftUI

@main
struct SmritiApp: App {
//s    @AppStorage("isOnboarding") private var isOnboarding: Bool = true
    
    var body: some Scene {
        WindowGroup {
            RootView {
//                if isOnboarding {
//                    Onboarding()
//                } else {
                    ContentView()
//                }
            }
        }
    }
}
