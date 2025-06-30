//
//  GitHubFileService.swift
//  Smriti
//
//  Created by Aarav Gupta on 19/06/25.
//

import Foundation

final class GitHubFileService {

    static let shared = GitHubFileService()

    private init() {}

    /// Upload or update a `.md` note to the GitHub repo.
    func uploadOrUpdateNote(
        accessToken: String,
        repoFullName: String,
        filePath: String,
        noteContent: String,
        commitMessage: String = "Add or update note",
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // Step 1: Check if file exists to get SHA
        let fileURL = URL(string: "https://api.github.com/repos/\(repoFullName)/contents/\(filePath)")!
        var getRequest = URLRequest(url: fileURL)
        getRequest.httpMethod = "GET"
        getRequest.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: getRequest) { data, _, _ in
            var sha: String? = nil

            if let data = data {
                do {
                    let json = try JSONDecoder().decode([String: AnyDecodable].self, from: data)
                    sha = json["sha"]?.value as? String
                } catch {
                    print("SHA decode error: \(error.localizedDescription)")
                }
            }

            // Step 2: Upload or update file
            var uploadRequest = URLRequest(url: fileURL)
            uploadRequest.httpMethod = "PUT"
            uploadRequest.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
            uploadRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let encodedContent = Data(noteContent.utf8).base64EncodedString()
            let body = GitHubFileUploadRequest(
                message: commitMessage,
                content: encodedContent,
                sha: sha
            )

            uploadRequest.httpBody = try? JSONEncoder().encode(body)

            URLSession.shared.dataTask(with: uploadRequest) { data, _, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    guard data != nil else {
                        completion(.failure(GitHubServiceError.noData))
                        return
                    }

                    completion(.success(()))
                }
            }.resume()
        }.resume()
    }
    
    func downloadNotes(
        accessToken: String,
        repoFullName: String,
        completion: @escaping (Result<[SmritiNote], Error>) -> Void
    ) {
        let url = URL(string: "https://api.github.com/repos/\(repoFullName)/contents")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(GitHubServiceError.noData)) }
                return
            }

            do {
                let decoder = JSONDecoder()
                let fileList = try decoder.decode([GitHubFileInfo].self, from: data)

                let markdownFiles = fileList.filter { $0.name.hasSuffix(".md") }

                let group = DispatchGroup()
                var notes: [SmritiNote] = []
                var errors: [Error] = []

                for file in markdownFiles {
                    guard let downloadURL = file.download_url else { continue }

                    group.enter()
                    URLSession.shared.dataTask(with: downloadURL) { data, _, error in
                        defer { group.leave() }

                        if let data = data, let content = String(data: data, encoding: .utf8) {
                            do {
                                let note = try NoteParser.parse(from: content)
                                notes.append(note)
                            } catch {
                                errors.append(error)
                            }
                        } else if let error = error {
                            errors.append(error)
                        }
                    }.resume()
                }

                group.notify(queue: .main) {
                    if !notes.isEmpty {
                        completion(.success(notes))
                    } else if let firstError = errors.first {
                        completion(.failure(firstError))
                    } else {
                        completion(.success([]))
                    }
                }

            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }

    /// Delete a GitHub repo.
    func deleteRepo(
        accessToken: String,
        repoFullName: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let url = URL(string: "https://api.github.com/repos/\(repoFullName)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(GitHubServiceError.invalidResponse))
                    return
                }

                if httpResponse.statusCode == 204 {
                    completion(.success(()))
                } else {
                    completion(.failure(NSError(domain: "DeleteFailed", code: httpResponse.statusCode)))
                }
            }
        }.resume()
    }
}

