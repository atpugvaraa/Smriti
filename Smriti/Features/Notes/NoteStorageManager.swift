//
//  NoteStorageManager.swift
//  Smriti
//
//  Created by Aarav Gupta on 20/06/25.
//

import Foundation

final class NoteStorageManager {
    static let shared = NoteStorageManager()
    private let notesDirectory: URL

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        notesDirectory = base.appendingPathComponent("notes", isDirectory: true)

        if !FileManager.default.fileExists(atPath: notesDirectory.path) {
            try? FileManager.default.createDirectory(at: notesDirectory, withIntermediateDirectories: true)
        }
    }

    func save(note: SmritiNote) throws {
        let safeFilename = sanitize(note.title) + ".md"
        let fileURL = notesDirectory.appendingPathComponent(safeFilename)

        let frontmatter = """
        ---
        id: \(note.id.uuidString)
        title: \(note.title)
        isHidden: \(note.isHidden)
        created: \(iso8601String(note.creationDate))
        updated: \(iso8601String(note.lastModified))
        ---

        """
        let fullContent = frontmatter + "\n" + note.content
        try fullContent.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func sanitize(_ title: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return title
            .components(separatedBy: invalidCharacters)
            .joined()
            .replacingOccurrences(of: " ", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func iso8601String(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
}
