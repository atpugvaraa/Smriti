//
//  GitHubUserService.swift
//  Smriti
//
//  Created by Aarav Gupta on 19/06/25.
//

import Foundation

final class GitHubUserService {

    static let shared = GitHubUserService()

    private init() {}

    /// Fetches the authenticated user's GitHub profile.
    ///
    /// - Parameters:
    ///   - accessToken: The OAuth token for authentication.
    ///   - completion: Called with `GitHubProfile` on success or `Error` on failure.
    func fetchUserProfile(accessToken: String, completion: @escaping (Result<GitHubProfile, Error>) -> Void) {
        let url = URL(string: "https://api.github.com/user")!
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
                let profile = try JSONDecoder().decode(GitHubProfile.self, from: data)
                completion(.success(profile))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
