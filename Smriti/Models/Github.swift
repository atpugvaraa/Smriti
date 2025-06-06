import Foundation

// MARK: - Device Flow Responses
struct GitHubDeviceCodeResponse: Codable {
    let device_code: String
    let user_code: String
    let verification_uri: String
    let expires_in: Int
    let interval: Int
    let verification_uri_complete: String?
}

struct GitHubAccessTokenResponse: Codable {
    let access_token: String?
    let token_type: String?
    let scope: String?
    let error: String?
    let error_description: String?
    let error_uri: String?
}

// MARK: - GitHub Profile

struct GitHubProfile: Codable {
    let login: String
    let avatar_url: URL
    let name: String?
    let bio: String?
}

// MARK: - GitHub Repo

struct GitHubRepo: Codable, Identifiable {
    let id: Int
    let name: String
    let full_name: String
    let description: String?
    let html_url: URL
    let fork: Bool
    let privateRepo: Bool

    // Map JSON "private" to "privateRepo"
    private enum CodingKeys: String, CodingKey {
        case id, name, full_name, description, html_url, fork
        case privateRepo = "private"
    }
}

// Helper struct for API request/response
struct GitHubFileUploadRequest: Encodable {
    let message: String
    let content: String
    let sha: String?            // this is only needed if updating that repo..
}

struct GitHubFileUploadResponse: Decodable {
    let content: GitHubFileContent?
    let commit: GitHubCommit?
    struct GitHubFileContent: Decodable {
        let sha: String
        let path: String
        let name: String
    }
    struct GitHubCommit: Decodable {
        let sha: String
        let message: String
    }
}
// MARK: - Repo Creation API Request
struct GitHubCreateRepoRequest: Encodable {
    let name: String
    let description: String?
    let `private`: Bool
    let auto_init: Bool = true
}

struct GitHubRepoResponse: Decodable {
    let id: Int
    let full_name: String
    let html_url: URL
    let name: String
    let description: String?
    let `private`: Bool
}
