//
//  CreateNoteSheet.swift
//  Smriti
//
//  Created by Aarav Gupta on 08/06/25.
//

import SwiftUI

struct CreateNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var noteTitle = ""
    @State private var noteContent = ""
    @State private var repoName = "Smriti-"
    @State private var isPrivateRepo = true
    @State private var readmeContent = ""
    @State private var showReadmeWarning = false

    var onUpload: (String, String, String, Bool, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Note Title") {
                    TextField("Enter note title", text: $noteTitle)
                        .autocapitalization(.words)
                }
                Section("Note Content") {
                    TextEditor(text: $noteContent)
                        .frame(height: 120)
                }
                Section("GitHub Repo Name") {
                    TextField("e.g. Smriti-Notes, Smriti-Images-Backup", text: $repoName)
                        .autocapitalization(.none)
                }
                Section("Visibility") {
                    Toggle(isOn: $isPrivateRepo) {
                        Label(isPrivateRepo ? "Private" : "Public", systemImage: isPrivateRepo ? "lock.fill" : "globe")
                    }
                }
                Section("README.md (Optional)") {
                    TextEditor(text: $readmeContent).frame(height: 80)
                    if showReadmeWarning && readmeContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("“The developer worked hard on this app... and you’re not gonna add something to the README.md file? 😅”")
                            .foregroundColor(.orange)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .navigationTitle("Create Note")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Upload") {
                        if !noteTitle.isEmpty, !noteContent.isEmpty, !repoName.isEmpty {
                            if readmeContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                showReadmeWarning = true
                            }
                            onUpload(noteTitle, noteContent, repoName, isPrivateRepo, readmeContent)
                        }
                    }
                    .disabled(noteTitle.isEmpty || noteContent.isEmpty || repoName.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
