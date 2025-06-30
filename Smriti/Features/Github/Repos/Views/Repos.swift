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
    @State private var isDeleting = false
    @State private var github = GitHubService.shared

    var body: some View {
        NavigationStack {
            NavigationBarView(title: "Repos", scrollOffset: $scrollOffset) {
                if !github.isLoggedIn {
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
                        if github.repos.isEmpty {
                            VStack(spacing: 16) {
                                ProgressView("Loading repositories…")
                                Text("No repositories found.")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(github.repos) { repo in
                                    RepoCardView(repo: repo)
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, 20)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                repoToDelete = repo
                                                showDeleteOverlay = true
                                            } label: {
                                                Label("Delete Repo", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding(.top)
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
                        github.deleteRepo(repo: repo) { success in
                            DispatchQueue.main.async {
                                isDeleting = false
                                showDeleteOverlay = false
                                repoToDelete = nil
                                github.refreshRepos()
                            }
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
