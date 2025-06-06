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
        VStack {
            Spacer()
            
            Text("Log in to github")
            
            Text("Setup device flow")
            
            Text("Enjoy!")
            
            Spacer()
            
            Button {
                isOnboarding = false
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.green)
            }
            .padding(100)
        }
    }
}

#Preview {
    Onboarding()
}
