//
//  NoteParser.swift
//  Smriti
//
//  Created by Aarav Gupta on 20/06/25.
//

import Foundation
import Yams

enum NoteParserError: Error {
    case invalidFormat
    case yamlParseError
}

struct NoteParser {
    
    static func parse(from markdown: String) throws -> SmritiNote {
        // Step 1: Split YAML frontmatter and content
        guard markdown.hasPrefix("---") else {
            throw NoteParserError.invalidFormat
        }
        
        let parts = markdown.components(separatedBy: "---").dropFirst()
        guard parts.count >= 2 else {
            throw NoteParserError.invalidFormat
        }

        let yamlString = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let content = parts.dropFirst().joined(separator: "---").trimmingCharacters(in: .whitespacesAndNewlines)

        // Step 2: Parse YAML into a dictionary
        guard let yaml = try Yams.load(yaml: yamlString) as? [String: Any] else {
            throw NoteParserError.yamlParseError
        }

        // Step 3: Extract fields
        let title = yaml["title"] as? String ?? "Untitled"
        let tag = yaml["tag"] as? String
        let isFavorite = yaml["favorite"] as? Bool ?? false
        let createdStr = yaml["created"] as? String
        let creationDate = ISO8601DateFormatter().date(from: createdStr ?? "") ?? Date()

        return SmritiNote(
            title: title,
            content: content,
            creationDate: creationDate,
            lastModified: Date(), // You can set this from file metadata if needed
            isFavorite: isFavorite,
            tag: tag
        )
    }
}
