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
                                    ForEach(0...24, id: \.self) { _ in
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

// MARK: - RepoCardView
struct RepoCardView: View {
    let repo: GitHubRepo
    var onDelete: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )
                .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1.2)
                )

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(repo.name)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    if repo.privateRepo {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.yellow)
                            .font(.title2)
                            .shadow(radius: 2)
                    } else {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                            .font(.title2)
                            .shadow(radius: 1)
                    }
                    if let onDelete = onDelete {
                        Button(role: .destructive, action: onDelete) {
                            Image(systemName: "trash")
                                .padding(8)
                                .background(Color.red.opacity(0.15), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.red)
                        .accessibilityLabel("Delete Repo")
                    }
                }
                if let desc = repo.description, !desc.isEmpty {
                    Text(desc)
                        .font(.callout)
                        .foregroundColor(Color.white.opacity(0.7))
                        .lineLimit(2)
                }
                Spacer(minLength: 6)
                Link("Open in GitHub", destination: repo.html_url)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.blue)
                    .padding(.vertical, 4)
            }
            .padding(20)
        }
        .frame(minHeight: 110)
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .transition(.scale)
    }
}

// MARK: - DeleteRepoOverlay
struct DeleteRepoOverlay: View {
    let repo: GitHubRepo
    var isDeleting: Bool
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Delete Repository?")
                .font(.title2.bold())
            Text("Are you sure you want to permanently delete\n“\(repo.name)”?\n\nThis cannot be undone.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            HStack {
                Button("Cancel", action: onCancel)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                Button(role: .destructive, action: onConfirm) {
                    if isDeleting {
                        ProgressView()
                    } else {
                        Text("Delete")
                    }
                }
                .padding()
                .background(Color.red.opacity(0.12))
                .foregroundColor(.red)
                .clipShape(Capsule())
            }
        }
        .padding(32)
        .frame(maxWidth: 350)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(radius: 24)
        .padding()
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
