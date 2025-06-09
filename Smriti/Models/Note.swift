//
//  Note.swift
//  Smriti
//
//  Created by Aarav Gupta on 08/06/25.
//

import SwiftUI

struct Note {
    var id = UUID().uuidString
    var text: String
    var date: Date = Date()
    var isFavorite: Bool = false
    var tag: String?
}
