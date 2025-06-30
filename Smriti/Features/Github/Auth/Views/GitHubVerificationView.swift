//
//  GitHubVerificationView.swift
//  Smriti
//
//  Created by Aarav Gupta on 19/06/25.
//


import SwiftUI

struct GitHubVerificationView: View {
    let auth: GitHubAuthService
    @Binding var didCopyCode: Bool

    var body: some View {
        VStack(spacing: 16) {
            ProgressView("Waiting for browser login...")

            if let url = auth.verificationUri, let code = auth.userCode {
                Text("Go to:")
                    .font(.headline)
                Text(url)
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Text("Enter code:")
                    Text(code)
                        .font(.system(.title2, design: .monospaced))
                        .bold()
                        .padding(6)
                        .background(.thinMaterial)
                        .cornerRadius(8)
                        .onAppear {
                            UIPasteboard.general.string = code
                            didCopyCode = true
                        }

                    Button {
                        UIPasteboard.general.string = code
                        didCopyCode = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            didCopyCode = false
                        }
                    } label: {
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

            Button("Cancel") {
                auth.logout()
            }
            .foregroundStyle(.red)
            .padding(.top)
        }
    }
}
