//
//  GitHubLoginCard.swift
//  Smriti
//
//  Created by Aarav Gupta on 19/06/25.
//

import SwiftUI

struct GitHubLoginCard: View {
    @State private var didCopyCode = false
    @State private var auth = GitHubAuthService.shared

    var body: some View {
        VStack(spacing: 24) {

            // Error
            if let error = auth.errorMessage {
                Text("⚠️ \(error)")
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            if auth.isLoggedIn {
                if let profile = GitHubService.shared.profile {
                    GitHubProfileCardView(profile: profile)
                }
            } else {
                if auth.isWaiting {
                    GitHubVerificationView(
                        auth: auth,
                        didCopyCode: $didCopyCode
                    )
                } else {
                    GitHubLoginPromptView(auth: auth)
                }
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut, value: auth.isLoggedIn)
        .animation(.easeInOut, value: auth.isWaiting)
    }
}
