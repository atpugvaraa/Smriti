//
//  StorageMode.swift
//  Smriti
//
//  Created by Aarav Gupta on 19/06/25.
//

import SwiftUI

enum StorageMode: String, Codable {
    case github, icloud, local
}

@Observable class AppState {
    var selectedStorage: StorageMode = .github // can be changed by user
}
