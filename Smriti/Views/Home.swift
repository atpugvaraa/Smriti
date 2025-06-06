//
//  Home.swift
//  Smriti
//
//  Created by Aarav Gupta on 03/06/25.
//

import SwiftUI

struct Home: View {
    @State private var auth = GitHubAuth.shared
    @State private var scrollOffset: CGFloat = 0
    @State private var didCopyCode = false

    var body: some View {
        NavigationStack {
            NavigationBarView(title: "Smriti", scrollOffset: $scrollOffset) {
                VStack(spacing: 24) {
                    // MARK: - Show error if any
                    if let error = auth.errorMessage {
                        Text("⚠️ \(error)")
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    // MARK: - Not logged in
                    if !auth.isLoggedIn {
                        if auth.isWaiting {
                            VStack(spacing: 16) {
                                ProgressView("Waiting for browser login...")
                                if let url = auth.verificationUri, let code = auth.userCode {
                                    Text("Go to: \(url)")
                                        .font(.headline)
                                        .multilineTextAlignment(.center)
                                        .padding(.top)
                                    HStack(spacing: 12) {
                                        Text("Enter code: ")
                                        Text(code)
                                            .font(.system(.largeTitle, design: .monospaced))
                                            .bold()
                                            .padding(6)
                                            .background(.thinMaterial)
                                            .cornerRadius(8)
                                        Button(action: {
                                            UIPasteboard.general.string = code
                                            didCopyCode = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                didCopyCode = false
                                            }
                                        }) {
                                            Image(systemName: didCopyCode ? "checkmark" : "doc.on.doc")
                                        }
                                        .buttonStyle(.bordered)
                                        .foregroundColor(didCopyCode ? .green : .blue)
                                        .accessibilityLabel("Copy code")
                                    }
                                    if didCopyCode {
                                        Text("Copied!")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                            .transition(.opacity)
                                    }
                                }
                                Button("Cancel") { auth.logout() }
                                    .foregroundStyle(.red)
                                    .padding(.top)
                            }
                        } else {
                            Button {
                                auth.startDeviceFlow()
                            } label: {
                                Label("Login with GitHub", systemImage: "arrow.right.square")
                                    .font(.title2)
                                    .padding()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }


                    // MARK: - Logged in: Profile card
                    if auth.isLoggedIn, let profile = auth.profile {
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
                            if let name = profile.name { Text(name).font(.headline) }
                            if let bio = profile.bio { Text(bio).font(.body).multilineTextAlignment(.center) }
                            Button("Log Out", role: .destructive) { auth.logout() }
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: 300)
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(radius: 8)
                    }
                }
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    Home()
        .environment(GitHubAuth())
}
