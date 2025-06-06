//
//  NotesCard.swift
//  Smriti
//
//  Created by Aarav Gupta on 03/06/25.
//

import SwiftUI

enum NotesCardStyle {
    case square
    case horizontal
    case vertical
    
    static func random() -> NotesCardStyle {
        [.square, .horizontal, .vertical].randomElement()!
    }
}

struct NotesCard: View {
    var style: NotesCardStyle = .square
    
    var aspectRatio: CGFloat {
        switch style {
        case .square: return 1
        case .horizontal: return 3/2
        case .vertical: return 2/3
        }
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.primary)
                .offset(x: 4, y: 4)

            Rectangle()
                .fill(.background)
                .border(.primary, width: 1)

            GeometryReader { proxy in
                let size = proxy.size

                Triangle()
                    .frame(width: 4.5, height: 4.5)
                    .rotationEffect(.degrees(90))
                    .frame(width: size.width, height: size.height, alignment: .topTrailing)
                    .offset(x: 3.9, y: -0.3)

                Triangle()
                    .frame(width: 4.5, height: 4.5)
                    .rotationEffect(.degrees(-90))
                    .frame(width: size.width, height: size.height, alignment: .bottomLeading)
                    .offset(x: -0.35, y: 3.8)
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }
}


#Preview {
    NotesCard()
}
