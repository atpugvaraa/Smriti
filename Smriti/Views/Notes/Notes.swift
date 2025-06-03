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

struct Notes: View {
    @EnvironmentObject var github: GitHubAuthViewModel
    @State private var showSheet = false
    @State private var isUploading = false
    @State private var uploadStatus: String?
    @State private var uploadURL: URL?
    @State private var step: GitHubUploadStep?

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        NavigationStack {
            NavigationBarView(title: "Notes", scrollOffset: .constant(0)) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Button {
                            showSheet = true
                        } label: {
                            Label("New Note", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                        .disabled(isUploading || !github.isLoggedIn)
                        Spacer()
                        if isUploading {
                            ProgressView("Uploading…").padding(.trailing, 6)
                        }
                    }
                    .padding(.bottom, 6)

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
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.bottom, 4)
                    }

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(0..<10, id: \.self) { _ in
                            NotesCard(width: 170, height: 170)
                        }
                    }
                }
                .padding()
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
                    .presentationDetents([.medium, .large])
                }
            }
        }
    }
}

struct CreateNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var noteTitle = ""
    @State private var noteContent = ""
    @State private var repoName = ""
    @State private var isPrivateRepo = false
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
                    TextEditor(text: $noteContent).frame(height: 120)
                }
                Section("GitHub Repo Name") {
                    TextField("e.g. my-notes-repo", text: $repoName)
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

#Preview {
    Notes().environmentObject(GitHubAuthViewModel())
}
