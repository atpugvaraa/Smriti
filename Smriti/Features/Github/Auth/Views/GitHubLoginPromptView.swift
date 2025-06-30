//
//  GitHubLoginPromptView.swift
//  Smriti
//
//  Created by Aarav Gupta on 19/06/25.
//


import SwiftUI

struct GitHubLoginPromptView: View {
    let auth: GitHubAuthService

    var body: some View {
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
