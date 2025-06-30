//
//  GitHubService.swift
//  Smriti
//
//  Created by Aarav Gupta on 19/06/25.
//

//
//  GitHubService.swift
//  Smriti
//

import Foundation
import UIKit

@Observable
final class GitHubService {
    static let shared = GitHubService()

    // MARK: - Public UI State
    var profile: GitHubProfile?
    var repos: [GitHubRepo] = []
    var errorMessage: String?

    private init() {
        if isLoggedIn, let token = GitHubAuthService.shared.accessToken {
            Task {
                await refreshUserData(with: token)
            }
        }
    }

    var isLoggedIn: Bool {
        GitHubAuthService.shared.isLoggedIn
    }

    var userCode: String? {
        GitHubAuthService.shared.userCode
    }

    var verificationUri: String? {
        GitHubAuthService.shared.verificationUri
    }

    var isWaiting: Bool {
        GitHubAuthService.shared.isWaiting
    }

    // MARK: - Auth Interface

    func login() {
        GitHubAuthService.shared.startDeviceFlow()
    }

    func logout() {
        GitHubAuthService.shared.logout()
        profile = nil
        repos = []
    }

    // MARK: - Repo Interface

    func createOrGetRepo(
        name: String,
        description: String = "",
        isPrivate: Bool = false,
        completion: @escaping (Result<GitHubRepoResponse, Error>) -> Void
    ) {
        guard let token = GitHubAuthService.shared.accessToken else {
            completion(.failure(GitHubServiceError.unauthorized))
            return
        }

        GitHubRepoService.shared.createOrGetRepo(
            accessToken: token,
            name: name,
            description: description,
            isPrivate: isPrivate,
            completion: completion
        )
    }
    
    func deleteRepo(repo: GitHubRepo, completion: @escaping (Bool) -> Void) {
        guard let token = GitHubAuthService.shared.accessToken else {
            completion(false)
            return
        }

        GitHubFileService.shared.deleteRepo(accessToken: token, repoFullName: repo.full_name) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.repos.removeAll { $0.id == repo.id }
                    completion(true)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }

    func fetchNotes(from repo: String, completion: @escaping (Result<[SmritiNote], Error>) -> Void) {
        guard let token = GitHubAuthService.shared.accessToken else {
            completion(.failure(GitHubServiceError.unauthorized))
            return
        }

        GitHubFileService.shared.downloadNotes(
            accessToken: token,
            repoFullName: repo,
            completion: completion
        )
    }

    func uploadNote(
        repo: String,
        path: String,
        noteContent: String,
        commitMessage: String = "Add or update note",
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let token = GitHubAuthService.shared.accessToken else {
            completion(.failure(GitHubServiceError.unauthorized))
            return
        }

        GitHubFileService.shared.uploadOrUpdateNote(
            accessToken: token,
            repoFullName: repo,
            filePath: path,
            noteContent: noteContent,
            commitMessage: commitMessage,
            completion: completion
        )
    }

    // MARK: - Load Profile + Repos

    func refreshUserData(with token: String) async {
        async let profileResult = withCheckedContinuation { continuation in
            GitHubUserService.shared.fetchUserProfile(accessToken: token) {
                continuation.resume(returning: $0)
            }
        }

        async let reposResult = withCheckedContinuation { continuation in
            GitHubRepoService.shared.fetchUserRepos(accessToken: token) {
                continuation.resume(returning: $0)
            }
        }

        do {
            let profile = try await profileResult.get()
            let repos = try await reposResult.get()
            DispatchQueue.main.async {
                self.profile = profile
                self.repos = repos
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func refreshRepos() {
        guard let token = GitHubAuthService.shared.accessToken else { return }
        GitHubRepoService.shared.fetchUserRepos(accessToken: token) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let repos):
                    self.repos = repos
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
