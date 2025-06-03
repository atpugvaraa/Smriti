//
//  NotesCard.swift
//  Smriti
//
//  Created by Aarav Gupta on 03/06/25.
//

import SwiftUI

struct NotesCard: View {
    var width: CGFloat
    var height: CGFloat
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let safeArea = proxy.safeAreaInsets
            
            ZStack {
                Rectangle()
                    .fill(.primary)
                    .offset(x: 2, y: 2)
                    .overlay {
                        Rectangle()
                            .rotation(.degrees(45))
                            .fill(.primary)
                            .frame(height: 240.416)
                            .frame(width: 2.7)
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
    NotesCard(width: 170, height: 170)
}
