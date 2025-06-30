//
//  GitHubRepoService.swift
//  Smriti
//
//  Created by Aarav Gupta on 19/06/25.
//

import Foundation

final class GitHubRepoService {

    static let shared = GitHubRepoService()

    private init() {}

    /// Fetch all repositories accessible by the authenticated user.
    func fetchUserRepos(accessToken: String, completion: @escaping (Result<[GitHubRepo], Error>) -> Void) {
        let url = URL(string: "https://api.github.com/user/repos?per_page=100&type=all&sort=updated")!
        var request = URLRequest(url: url)
        request.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(GitHubServiceError.noData))
                return
            }

            do {
                let repos = try JSONDecoder().decode([GitHubRepo].self, from: data)
                completion(.success(repos))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    /// Fetches user login and checks if a repo exists, else creates it.
    func createOrGetRepo(
        accessToken: String,
        name: String,
        description: String = "",
        isPrivate: Bool = false,
        completion: @escaping (Result<GitHubRepoResponse, Error>) -> Void
    ) {
        // Step 1: Get user info
        GitHubUserService.shared.fetchUserProfile(accessToken: accessToken) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let profile):
                let owner = profile.login
                let repoURL = URL(string: "https://api.github.com/repos/\(owner)/\(name)")!

                var checkRequest = URLRequest(url: repoURL)
                checkRequest.httpMethod = "GET"
                checkRequest.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")

                URLSession.shared.dataTask(with: checkRequest) { repoData, _, _ in
                    if let repoData = repoData,
                       let existing = try? JSONDecoder().decode(GitHubRepoResponse.self, from: repoData) {
                        completion(.success(existing))
                        return
                    }

                    // Step 2: Create repo
                    let createURL = URL(string: "https://api.github.com/user/repos")!
                    var createRequest = URLRequest(url: createURL)
                    createRequest.httpMethod = "POST"
                    createRequest.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
                    createRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let createPayload = GitHubCreateRepoRequest(
                        name: name,
                        description: description,
                        private: isPrivate
                    )

                    createRequest.httpBody = try? JSONEncoder().encode(createPayload)

                    URLSession.shared.dataTask(with: createRequest) { data, _, error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }

                        guard let data = data else {
                            completion(.failure(GitHubServiceError.noData))
                            return
                        }

                        do {
                            let newRepo = try JSONDecoder().decode(GitHubRepoResponse.self, from: data)
                            completion(.success(newRepo))
                        } catch {
                            completion(.failure(error))
                        }
                    }.resume()
                }.resume()
            }
        }
    }
}
