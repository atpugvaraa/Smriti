//
//  Notes.swift
//  Smriti
//
//  Created by Aarav Gupta on 03/06/25.
//

import SwiftUI

struct Notes: View {
    @State private var github = GitHubAuth.shared
    @State private var showSheet = false
    @State private var showNewNote = false
    @State private var isUploading = false
    @State private var uploadStatus: String?
    @State private var uploadURL: URL?
    @State private var step: GitHubUploadStep?
    @State private var scrollOffset: CGFloat = 0
    @State private var userNotes: [Note] = []

    let notes = Array(0...24)

    var body: some View {
        NavigationStack {
            NavigationBarView(title: "Notes", scrollOffset: $scrollOffset) {
                VStack(alignment: .leading, spacing: 18) {
                    if let step {
                        VStack(alignment: .leading, spacing: 2) {
                            ProgressView(value: Double(step.rawValue), total: Double(GitHubUploadStep.allCases.count - 1))
                                .progressViewStyle(.linear)
                            Text(step.title).font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .transition(.opacity)
                    }

                    if let status = uploadStatus {
                        HStack {
                            Text(status)
                                .foregroundStyle(uploadURL != nil ? .green : .red)
                                .font(.callout)
                            if let url = uploadURL {
                                Button("Open Repo") { UIApplication.shared.open(url) }
                                    .font(.footnote)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.bottom, 4)
                    }

                    ScrollView {
                        let (leftColumn, rightColumn) = splitIntoColumns(notes)
                        
                        HStack(alignment: .top, spacing: 16) {
                            LazyVStack(spacing: 16) {
                                ForEach(leftColumn, id: \.self) { _ in
                                    NotesCard(style: .random())
                                }
                            }
                            
                            LazyVStack(spacing: 16) {
                                ForEach(rightColumn, id: \.self) { _ in
                                    NotesCard(style: .random())
                                }
                            }
                        }
                        .padding()
                    }
                }
                .sheet(isPresented: $showSheet) {
                    CreateNoteSheet { title, content, repo, isPrivate, readme in
                        isUploading = true
                        uploadStatus = nil
                        uploadURL = nil
                        step = .connect
                        let notePath = "notes/\(title.replacingOccurrences(of: " ", with: "-"))-\(UUID().uuidString.prefix(6)).md"
                        let readmePath = "README.md"
                        step = .preparing
                        github.createOrGetRepo(name: repo, description: "Notes repo created from Smriti app", isPrivate: isPrivate) { result in
                            step = .creatingRepo
                            switch result {
                            case .success(let ghRepo):
                                step = .uploadingNote
                                github.uploadOrUpdateNote(repo: ghRepo.full_name, path: notePath, noteContent: content, commitMessage: "Add note: \(title)") { uploadResult in
                                    switch uploadResult {
                                    case .success:
                                        if !readme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            step = .uploadingReadme
                                            github.uploadOrUpdateNote(repo: ghRepo.full_name, path: readmePath, noteContent: readme, commitMessage: "Update README.md") { readmeResult in
                                                finishUpload(readmeResult, url: ghRepo.html_url, successMsg: "Note & README uploaded!")
                                            }
                                        } else {
                                            finishUpload(.success(()), url: ghRepo.html_url, successMsg: "Uploaded successfully! (No README)")
                                        }
                                    case .failure(let err):
                                        finishUpload(.failure(err), url: nil, successMsg: nil)
                                    }
                                }
                            case .failure(let err):
                                finishUpload(.failure(err), url: nil, successMsg: nil)
                            }
                        }
                        func finishUpload(_ result: Result<Void, Error>, url: URL?, successMsg: String?) {
                            isUploading = false
                            step = .done
                            showSheet = false
                            switch result {
                            case .success:
                                uploadStatus = successMsg
                                uploadURL = url
                            case .failure(let err):
                                uploadStatus = "Failed: \(err.localizedDescription)"
                            }
                        }
                    }
                    .presentationDetents([.large])
                }
            }
            .universalOverlay(show: $showNewNote) {
                #warning("Fix the colors + padding")
                Button {
                    showSheet = true
                } label: {
                    ZStack {
                        Circle()
                            .foregroundStyle(.primary)
                            .offset(x: 3, y: 3.3)
                        
                        Circle()
                            .fill(.background)
                            .stroke(.primary, lineWidth: 1)
                        
                        Text("New Note")
                            .fontWeight(.medium)
                            .fontWidth(.expanded)
                            .foregroundStyle(.primary)
                        
                        Circle()
                            .foregroundStyle(github.isLoggedIn ? .clear : .gray.opacity(0.7))
                    }
                    .frame(width: 75)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 25)
                    .padding(.bottom, 59)
                }
                .disabled(isUploading || !github.isLoggedIn)
                Spacer()
                if isUploading {
                    ProgressView("Uploading…")
                        .padding(.trailing, 6)
                }
            }
            .onAppear {
                showNewNote = true
            }
        }
    }
}

#Preview {
    RootView {
        Notes()
    }
}


extension View {
    func splitIntoColumns<T>(_ items: [T]) -> ([T], [T]) {
        var col1: [T] = []
        var col2: [T] = []
        
        for (index, item) in items.enumerated() {
            if index % 2 == 0 {
                col1.append(item)
            } else {
                col2.append(item)
            }
        }
        
        return (col1, col2)
    }
}
