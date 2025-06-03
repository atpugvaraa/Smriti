//
//  RepoCard.swift
//  Smriti
//
//  Created by Aarav Gupta on 03/06/25.
//

import SwiftUI

struct RepoCard: View {
    var width: CGFloat
    var height: CGFloat
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            
            // 1. Calculate angle in degrees
            let angle = atan(width / height) * 180 / .pi
            
            // 2. Calculate hypotenuse
            let hypotenuse = sqrt(pow(width, 2) + pow(height, 2))
            
            ZStack {
                Rectangle()
                    .fill(.primary)
                    .offset(x: 2, y: 2)
                    .overlay {
                        Rectangle()
                            .fill(.primary)
                            .rotationEffect(.degrees(angle))
                            .frame(width: 2.7, height: hypotenuse)
                            .offset(x: 1.1, y: 1.1)
                    }
                
                Rectangle()
                    .fill(.background)
                    .border(.primary, width: 3)
            }
            .frame(width: size.width, height: size.height)
        }
        .frame(width: width, height: height)
    }
}

#Preview {
    RepoCard(width: 320, height: 85)
}
