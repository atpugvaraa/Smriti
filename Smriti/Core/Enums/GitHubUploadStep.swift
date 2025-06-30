//
//  GitHubUploadStep.swift
//  Smriti
//
//  Created by Aarav Gupta on 08/06/25.
//

import SwiftUI

enum GitHubUploadStep: Int, CaseIterable, Identifiable {
    case connect, preparing, creatingRepo, uploadingNote, uploadingReadme, done
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .connect: return "Connecting to GitHub"
        case .preparing: return "Preparing Data"
        case .creatingRepo: return "Creating Repository"
        case .uploadingNote: return "Uploading Note"
        case .uploadingReadme: return "Uploading README.md"
        case .done: return "All Done!"
        }
    }
}
