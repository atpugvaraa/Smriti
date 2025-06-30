//
//  GitHubProfileCardView.swift
//  Smriti
//
//  Created by Aarav Gupta on 19/06/25.
//


import SwiftUI

struct GitHubProfileCardView: View {
    let profile: GitHubProfile

    var body: some View {
        VStack(spacing: 16) {
            AsyncImage(url: profile.avatar_url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                case .failure:
                    Image(systemName: "person.crop.circle.badge.exclam")
                        .resizable()
                        .frame(width: 90, height: 90)
                @unknown default:
                    EmptyView()
                }
            }

            Text(profile.login)
                .font(.title2)
                .fontWeight(.bold)

            if let name = profile.name {
                Text(name).font(.headline)
            }

            if let bio = profile.bio {
                Text(bio)
                    .font(.body)
                    .multilineTextAlignment(.center)
            }

            Button("Log Out", role: .destructive) {
                GitHubAuthService.shared.logout()
                GitHubService.shared.logout()
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: 300)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 8)
    }
}
