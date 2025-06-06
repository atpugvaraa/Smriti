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


#Preview {
    RepoCard()
}
