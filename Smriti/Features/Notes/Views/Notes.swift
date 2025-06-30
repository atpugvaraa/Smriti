//
//  Notes.swift
//  Smriti
//
//  Created by Aarav Gupta on 03/06/25.
//

import SwiftUI

struct Notes: View {
    @Environment(GitHubService.self) var github
    @State private var showSheet = false
    @State private var showNewNote = false
    @State private var isUploading = false
    @State private var uploadStatus: String?
    @State private var uploadURL: URL?
    @State private var step: GitHubUploadStep?
    @State private var scrollOffset: CGFloat = 0
    @State private var userNotes: [SmritiNote] = []

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
                        let (leftColumn, rightColumn) = splitIntoColumns(userNotes)
                        
                        HStack(alignment: .top, spacing: 16) {
                            LazyVStack(spacing: 16) {
                                ForEach(leftColumn) { note in
                                    NotesCard(note: note, style: .random())
                                }
                            }
                            LazyVStack(spacing: 16) {
                                ForEach(rightColumn) { note in
                                    NotesCard(note: note, style: .random())
                                }
                            }
                        }
                        .padding()
                    }
                }
                .navigationDestination(isPresented: $showSheet) {
                    NewNoteEditorView()
                }
            }
            .universalOverlay(show: $showNewNote) {
                #warning("Fix the colors + padding")
                Button {
                    showSheet = true
                } label: {
                    ZStack {
                        Circle().foregroundStyle(.primary).offset(x: 3, y: 3.3)
                        Circle().fill(.background).stroke(.primary, lineWidth: 1)
                        Text("New Note").fontWeight(.medium).fontWidth(.expanded).foregroundStyle(.primary)
                        Circle().foregroundStyle(github.isLoggedIn ? .clear : .gray.opacity(0.7))
                    }
                    .frame(width: 75)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 25)
                    .padding(.bottom, 59)
                }
                .disabled(!github.isLoggedIn)
                .buttonStyle(.plain)
                
                Spacer()
                
                if isUploading {
                    ProgressView("Uploading…")
                        .padding(.trailing, 6)
                }
            }
            .onAppear {
                showNewNote = true
                if let firstRepo = github.repos.first?.full_name {
                    github.fetchNotes(from: firstRepo) { result in
                        switch result {
                        case .success(let notes):
                            userNotes = notes.filter { !$0.isHidden }
                        case .failure(let error):
                            print("Failed to fetch notes: \(error)")
                        }
                    }
                }
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
