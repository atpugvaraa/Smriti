//
//  Repos.swift
//  Smriti
//
//  Created by Aarav Gupta on 03/06/25.
//

import SwiftUI

struct Repos: View {
    @State private var scrollOffset: CGFloat = 0
    @State private var showDeleteOverlay = false
    @State private var repoToDelete: GitHubRepo?
    @State private var repos: [SmritiRepo]?
    @State private var isDeleting = false
    @State private var auth = GitHubAuth.shared
    

    var body: some View {
        NavigationStack {
            NavigationBarView(title: "Repos", scrollOffset: $scrollOffset) {
                if !auth.isLoggedIn {
                    VStack(spacing: 16) {
                        Image(systemName: "lock.slash")
                            .resizable()
                            .frame(width: 48, height: 48)
                            .foregroundColor(.gray)
                        Text("Please login with GitHub to see your repositories.")
                            .multilineTextAlignment(.center)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        if auth.repos.isEmpty {
                            VStack(spacing: 16) {
                                ProgressView("Loading repositories…")
                                Text("No repositories found, or loading…")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                        } else {
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(0...10, id: \.self) { _ in
                                        RepoCard()
                                            .frame(maxWidth: .infinity)
                                            .padding(.horizontal, 20)
                                    }
                                }
                                .padding(.top)
                            }
                        }
                    }
                }
            }
        }
        .universalOverlay(show: $showDeleteOverlay) {
            if let repo = repoToDelete {
                DeleteRepoOverlay(
                    repo: repo,
                    isDeleting: isDeleting,
                    onConfirm: {
                        isDeleting = true
                        auth.deleteRepo(repo: repo) { success in
                            isDeleting = false
                            showDeleteOverlay = false
                            repoToDelete = nil
                            auth.fetchUserRepos()
                        }
                    },
                    onCancel: {
                        showDeleteOverlay = false
                        repoToDelete = nil
                    }
                )
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.7)]),
            startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        VStack(spacing: 24) {
            RepoCardView(repo: .init(
                id: 1,
                name: "VisionCode",
                full_name: "VisionCode/Code",
                description: "A Simple Code editor for html and css, + js",
                html_url: URL(string: "https://github.com/user/VisioNCode")!,
                fork: false,
                privateRepo: false
            ))
            RepoCardView(repo: .init(
                id: 2,
                name: "Smriti",
                full_name: "Smriti/Notes",
                description: "Your private repo, safe & sound.",
                html_url: URL(string: "https://github.com/user/Smriti")!,
                fork: false,
                privateRepo: true
            ))
        }
        .padding()
    }
}
