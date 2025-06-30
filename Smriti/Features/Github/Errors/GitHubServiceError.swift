//
//  GitHubServiceError.swift
//  Smriti
//
//  Created by Aarav Gupta on 19/06/25.
//

import Foundation

enum GitHubServiceError: Error, LocalizedError {
    case unauthorized
    case invalidRepo
    case noData
    case invalidResponse
    case unknown

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "You must be logged in to perform this action."
        case .invalidRepo: return "Repository not found or inaccessible."
        case .noData: return "No data was returned from the server."
        case .invalidResponse: return "The response from the server was invalid."
        case .unknown: return "An unknown error occurred."
        }
    }
}

