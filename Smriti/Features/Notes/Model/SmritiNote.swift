//
//  SmritiNote.swift
//  Smriti
//
//  Created by Aarav Gupta on 08/06/25.
//

import SwiftUI

struct SmritiNote: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var content: String
    var creationDate: Date = Date()
    var lastModified: Date
    var isFavorite: Bool = false
    var tag: String?
    var isHidden: Bool = false
}
