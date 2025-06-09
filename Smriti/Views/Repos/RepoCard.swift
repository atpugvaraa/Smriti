//
//  RepoCard.swift
//  Smriti
//
//  Created by Aarav Gupta on 03/06/25.
//

import SwiftUI

struct RepoCard: View {
    var body: some View {
        ViewThatFits {
            InternalCard(width: UIScreen.main.bounds.width - 40)
            InternalCard(width: 340) // fallback
        }
    }
}

private struct InternalCard: View {
    var width: CGFloat
    var height: CGFloat { width / 4 }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.primary)
                .frame(width: width, height: height)
                .offset(x: 4, y: 4)

            Rectangle()
                .fill(.background)
                .frame(width: width, height: height)
                .border(.primary, width: 1)

            Triangle()
                .frame(width: 4.5, height: 4.5)
                .rotationEffect(.degrees(90))
                .frame(width: width, height: height, alignment: .topTrailing)
                .offset(x: 3.8, y: -0.3)

            Triangle()
                .frame(width: 4.5, height: 4.5)
                .rotationEffect(.degrees(-90))
                .frame(width: width, height: height, alignment: .bottomLeading)
                .offset(x: -0.3, y: 3.8)
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
    RepoCard()
}
