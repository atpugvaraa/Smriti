//
//  SmritiApp.swift
//  Smriti
//
//  Created by Aarav Gupta on 02/06/25.
//

import SwiftUI

@main
struct SmritiApp: App {
    @AppStorage("isOnboarding") private var isOnboarding: Bool = true
    @State private var github = GitHubService.shared
    @State private var navigation = NavigationManager.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigation.path) {
                RootView {
                    if isOnboarding {
                        Onboarding()
                    } else {
                        ContentView()
                    }
                }
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .noteDetail(let note):
                        NoteDetailView(note: note)
//                    case .repoDetail(let repo):
//                        RepoDetailView(repo: repo)
                    }
                }
            }
            .environment(github)
            .environment(navigation)
        }
    }
}

