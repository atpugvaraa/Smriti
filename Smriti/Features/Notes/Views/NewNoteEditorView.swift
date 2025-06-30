//
//  NewNoteEditorView.swift
//  Smriti
//
//  Created by Aarav Gupta on 20/06/25.
//

import SwiftUI

struct NewNoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GitHubService.self) private var github

    @State private var note: SmritiNote
    @State private var debounceTimer: Timer?

    init() {
        let now = Date()
        let title = DateFormatter.localizedString(from: now, dateStyle: .long, timeStyle: .none)
        _note = State(initialValue: SmritiNote(
            title: title,
            content: "",
            lastModified: now,
            isHidden: false
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Note Title", text: $note.title)
                .font(.title)
                .padding()
                .onChange(of: note.title) { queueSave() }

            Divider()

            TextEditor(text: $note.content)
                .padding()
                .onChange(of: note.content) { queueSave() }
        }
        .navigationTitle("New Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    syncToGitHub()
                    dismiss()
                }
            }
        }
        .onDisappear {
            try? NoteStorageManager.shared.save(note: note)
        }
    }

    private func queueSave() {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
            note.lastModified = .now
            try? NoteStorageManager.shared.save(note: note)
        }
    }

    private func syncToGitHub() {
        guard github.isLoggedIn else { return }
        let repo = "Smriti-Notes"
        let path = "\(note.title.replacingOccurrences(of: " ", with: "-")).md"
        let frontmatter = """
        ---
        id: \(note.id.uuidString)
        title: \(note.title)
        isHidden: \(note.isHidden)
        created: \(note.creationDate)
        updated: \(note.lastModified)
        ---

        """ + "\n" + note.content

        github.createOrGetRepo(name: repo, description: "Smriti note repository", isPrivate: true) { result in
            switch result {
            case .success(let ghRepo):
                github.uploadNote(
                    repo: ghRepo.full_name,
                    path: path,
                    noteContent: frontmatter,
                    commitMessage: "Add or update note: \(note.title)"
                ) { uploadResult in
                    switch uploadResult {
                    case .success:
                        print("Note uploaded.")
                    case .failure(let error):
                        print("Upload failed: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                print("Failed to create/get repo: \(error.localizedDescription)")
            }
        }
    }
}
