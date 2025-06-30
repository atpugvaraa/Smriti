//
//  Onboarding.swift
//  Smriti
//
//  Created by Aarav Gupta on 03/06/25.
//

import SwiftUI

struct Onboarding: View {
    @AppStorage("isOnboarding") private var isOnboarding: Bool = true

    var body: some View {
        TabView {
            // Step 1 – GitHub Login
            VStack {
                Text("Login with GitHub")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                GitHubLoginCard()
                    .frame(maxHeight: .infinity)
            }
            .padding()

            // Step 2 – Device Setup
            VStack(spacing: 20) {
                Image(systemName: "gearshape.2.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)
                    .foregroundStyle(.blue)

                Text("Set up Device Flow")
                    .font(.title)
                    .bold()

                Text("Link your device securely to sync notes across platforms.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Step 3 – Done
            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)
                    .foregroundStyle(.green)

                Text("You're all set!")
                    .font(.title)
                    .bold()

                Text("Smriti is now ready to help you think, write, and remember beautifully.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Final Button
            VStack {
                Spacer()

                Button {
                    isOnboarding = false
                } label: {
                    Label("Get Started", systemImage: "arrow.right.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .clipShape(Capsule())
                }
                .padding()

                Spacer()
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}

#Preview {
    Onboarding()
}
