import Foundation
import UIKit
import Combine

class GitHubAuthViewModel: ObservableObject {
    // MARK: - Published State
    @Published var isLoggedIn = false
    @Published var isWaiting = false
    @Published var errorMessage: String?
    
    @Published var userCode: String?
    @Published var verificationUri: String?
    @Published var verificationUriComplete: String?
    @Published var didOpenVerificationURL = false
    
    @Published var accessToken: String?
    @Published var profile: GitHubProfile?
    @Published var repos: [GitHubRepo] = []
    
    // MARK: - Private State
    private var deviceCode: String?
    private var pollInterval: Int = 5
    private var pollTimer: Timer?
    
    // MARK: - Load GitHub Client ID from Config
    func getClientID() -> String? {
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let clientID = dict["GitHubClientID"] as? String {
            return clientID
        }
        print("Info.plist missing or GitHubClientID missing!")
        return nil
    }
    
    // MARK: - Start Device Flow
    func startDeviceFlow() {
        guard let clientID = getClientID() else {
            self.errorMessage = "Client ID not found. Please check Info.plist."
            return
        }
        let url = URL(string: "https://github.com/login/device/code")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let params = "client_id=\(clientID)&scope=repo%20read:user"
        request.httpBody = params.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        isWaiting = true
        errorMessage = nil
        print("// MARK: - Requesting Device Code from GitHub")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    self.isWaiting = false
                    print("// MARK: - Device code request error:", error)
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No data returned."
                    self.isWaiting = false
                    print("// MARK: - No data returned for device code request.")
                    return
                }
                
                // DEBUG: print raw data always
                let text = String(data: data, encoding: .utf8) ?? "<non-utf8 data>"
                print("// MARK: - Raw device code response:\n\(text)\n")
                
                // Try JSON decode, if fails show error + raw string
                if let text = String(data: data, encoding: .utf8) {
                    let pairs = text.split(separator: "&")
                    var dict = [String: String]()
                    for pair in pairs {
                        let parts = pair.split(separator: "=", maxSplits: 1).map { String($0) }
                        if parts.count == 2 {
                            dict[parts[0]] = parts[1].removingPercentEncoding ?? parts[1]
                        }
                    }
                    
                    self.userCode = dict["user_code"]
                    self.verificationUri = dict["verification_uri"]
                    self.deviceCode = dict["device_code"]
                    self.pollInterval = Int(dict["interval"] ?? "5") ?? 5
                    
                    // Open the URL in browser automatically
                    if let urlString = dict["verification_uri"], let url = URL(string: urlString), !self.didOpenVerificationURL {
                        UIApplication.shared.open(url, options: [:])
                        self.didOpenVerificationURL = true
                    }
                    
                    print("// MARK: - Parsed Device Code Response:")
                    print("""
                    device_code: \(self.deviceCode ?? "")
                    user_code: \(self.userCode ?? "")
                    verification_uri: \(self.verificationUri ?? "")
                    interval: \(self.pollInterval)
                    """)
                    self.startPollingForToken()
                } else {
                    self.errorMessage = "Failed to decode response as UTF-8 string"
                }
                
            }
        }.resume()
    }
    
    // MARK: - Poll for Access Token
    func startPollingForToken() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(pollInterval), repeats: true) { [weak self] _ in
            self?.pollForAccessToken()
        }
    }
    
    func pollForAccessToken() {
        guard let clientID = getClientID(), let deviceCode = deviceCode else { return }
        let url = URL(string: "https://github.com/login/oauth/access_token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let params = "client_id=\(clientID)&device_code=\(deviceCode)&grant_type=urn:ietf:params:oauth:grant-type:device_code"
        request.httpBody = params.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        print("// MARK: - Polling for Access Token...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Polling error: \(error.localizedDescription)"
                    self.isWaiting = false
                    self.pollTimer?.invalidate()
                    print("// MARK: - Poll error:", error)
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No data when polling."
                    self.isWaiting = false
                    self.pollTimer?.invalidate()
                    return
                }
                
                let text = String(data: data, encoding: .utf8) ?? "<non-utf8 data>"
                print("// MARK: - Raw access token response:\n\(text)\n")
                
                do {
                    let res = try JSONDecoder().decode(GitHubAccessTokenResponse.self, from: data)
                    if let token = res.access_token {
                        self.accessToken = token
                        self.isLoggedIn = true
                        self.isWaiting = false
                        self.pollTimer?.invalidate()
                        print("// MARK: - Access token received:", token)
                        self.fetchUserProfile()
                        self.fetchUserRepos()
                    } else if let errorType = res.error {
                        if errorType == "authorization_pending" {
                            // keep polling
                        } else if errorType == "slow_down" {
                            self.pollInterval += 5
                            self.startPollingForToken()
                        } else {
                            self.errorMessage = (res.error_description ?? errorType) + "\nResponse: \(text)"
                            self.isWaiting = false
                            self.pollTimer?.invalidate()
                            print("// MARK: - Access token error:", errorType)
                        }
                    }
                } catch {
                    self.errorMessage = """
                    Polling decode error: \(error.localizedDescription)
                    Response: \(text)
                    """
                    self.isWaiting = false
                    self.pollTimer?.invalidate()
                    print("// MARK: - Polling decode error:", error)
                }
            }
        }.resume()
    }
    
    // MARK: - Fetch Profile After Login
    func fetchUserProfile() {
        guard let accessToken else { return }
        let url = URL(string: "https://api.github.com/user")!
        var request = URLRequest(url: url)
        request.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
        print("// MARK: - Fetching GitHub profile...")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("// MARK: - Profile fetch error:", error)
                    self.errorMessage = "Profile error: \(error.localizedDescription)"
                    return
                }
                guard let data = data else { return }
                let text = String(data: data, encoding: .utf8) ?? "<non-utf8 data>"
                print("// MARK: - Raw profile response:\n\(text)\n")
                do {
                    let profile = try JSONDecoder().decode(GitHubProfile.self, from: data)
                    self.profile = profile
                    print("// MARK: - GitHub profile loaded:", profile)
                } catch {
                    print("// MARK: - Profile decode error:", error)
                    self.errorMessage = """
                    Profile decode error: \(error.localizedDescription)
                    Response: \(text)
                    """
                }
            }
        }.resume()
    }
    
    // MARK: - Fetch User Repos (All)
    func fetchUserRepos() {
        guard let accessToken else { return }
        let url = URL(string: "https://api.github.com/user/repos?per_page=100&type=all&sort=updated")!
        var request = URLRequest(url: url)
        request.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
        print("// MARK: - Fetching GitHub repos...")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("// MARK: - Repo fetch error:", error)
                    self.errorMessage = "Repo error: \(error.localizedDescription)"
                    return
                }
                guard let data = data else { return }
                let text = String(data: data, encoding: .utf8) ?? "<non-utf8 data>"
                print("// MARK: - Raw repos response:\n\(text)\n")
                do {
                    let repos = try JSONDecoder().decode([GitHubRepo].self, from: data)
                    self.repos = repos
                    print("// MARK: - GitHub repos loaded:", repos.map { $0.full_name })
                } catch {
                    print("// MARK: - Repo decode error:", error)
                    self.errorMessage = """
                    Repo decode error: \(error.localizedDescription)
                    Response: \(text)
                    """
                }
            }
        }.resume()
    }
    
    /// Create a repository for the user, or just succeed if it exists
    func createOrGetRepo(
        name: String,
        description: String = "",
        isPrivate: Bool = false,
        completion: @escaping (Result<GitHubRepoResponse, Error>) -> Void
    ) {
        guard let accessToken = accessToken else {
            completion(.failure(NSError(domain: "NoAccessToken", code: 401)))
            return
        }
        // 1. Try to fetch the repo (does it already exist?)
        let meURL = URL(string: "https://api.github.com/user")!
        var meReq = URLRequest(url: meURL)
        meReq.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
        meReq.httpMethod = "GET"
        URLSession.shared.dataTask(with: meReq) { meData, _, meErr in
            if let meErr = meErr {
                completion(.failure(meErr))
                return
            }
            guard let meData = meData,
                  let userInfo = try? JSONDecoder().decode(GitHubProfile.self, from: meData) else {
                completion(.failure(NSError(domain: "UserFetchFail", code: 402)))
                return
            }
            let repoOwner = userInfo.login
            let repoURL = URL(string: "https://api.github.com/repos/\(repoOwner)/\(name)")!
            var checkReq = URLRequest(url: repoURL)
            checkReq.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
            checkReq.httpMethod = "GET"
            URLSession.shared.dataTask(with: checkReq) { repoData, repoResp, repoErr in
                if let repoData = repoData,
                   let repo = try? JSONDecoder().decode(GitHubRepoResponse.self, from: repoData) {
                    // Already exists
                    completion(.success(repo))
                    return
                }
                // 2. If not, create it!
                let createURL = URL(string: "https://api.github.com/user/repos")!
                var req = URLRequest(url: createURL)
                req.httpMethod = "POST"
                req.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let createReq = GitHubCreateRepoRequest(name: name, description: description, private: isPrivate)
                req.httpBody = try? JSONEncoder().encode(createReq)
                URLSession.shared.dataTask(with: req) { data, _, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        guard let data = data else {
                            completion(.failure(NSError(domain: "RepoCreateFail", code: 403)))
                            return
                        }
                        do {
                            let repo = try JSONDecoder().decode(GitHubRepoResponse.self, from: data)
                            completion(.success(repo))
                        } catch {
                            print(String(data: data, encoding: .utf8) ?? "<no response>")
                            completion(.failure(error))
                        }
                    }
                }.resume()
            }.resume()
        }.resume()
    }
    
    /// Upload or update a file to a repo. Handles SHA if file exists.
    func uploadOrUpdateNote(
        repo: String,
        path: String,
        noteContent: String,
        commitMessage: String = "Add or update note",
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let accessToken = accessToken else {
            completion(.failure(NSError(domain: "NoAccessToken", code: 401)))
            return
        }
        // 1. Check if the file exists already (need SHA to update)
        let getFileURL = URL(string: "https://api.github.com/repos/\(repo)/contents/\(path)")!
        var getFileReq = URLRequest(url: getFileURL)
        getFileReq.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
        getFileReq.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: getFileReq) { data, _, _ in
            var sha: String? = nil
            if let data = data,
               let fileInfo = try? JSONDecoder().decode([String: AnyDecodable].self, from: data),
               let shaStr = fileInfo["sha"]?.value as? String {
                sha = shaStr
            }
            // 2. Prepare upload request
            let uploadURL = URL(string: "https://api.github.com/repos/\(repo)/contents/\(path)")!
            var uploadReq = URLRequest(url: uploadURL)
            uploadReq.httpMethod = "PUT"
            uploadReq.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
            uploadReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let fileContent = Data(noteContent.utf8).base64EncodedString()
            let uploadData = GitHubFileUploadRequest(
                message: commitMessage,
                content: fileContent,
                sha: sha
            )
            uploadReq.httpBody = try? JSONEncoder().encode(uploadData)
            
            URLSession.shared.dataTask(with: uploadReq) { data, _, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    guard let data = data else {
                        completion(.failure(NSError(domain: "NoData", code: 400)))
                        return
                    }
                    do {
                        let _ = try JSONDecoder().decode(GitHubFileUploadResponse.self, from: data)
                        completion(.success(()))
                    } catch {
                        print(String(data: data, encoding: .utf8) ?? "<no response>")
                        completion(.failure(error))
                    }
                }
            }.resume()
        }.resume()
    }
    
    /// Delete a GitHub repo by full name (user/repo). Calls completion(true) if successful.
    func deleteRepo(repo: GitHubRepo, completion: @escaping (Bool) -> Void) {
        guard let accessToken = accessToken else {
            completion(false)
            return
        }
        let url = URL(string: "https://api.github.com/repos/\(repo.full_name)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("token \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 {
                    // Success!
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    
    // MARK: - Logout
    func logout() {
        accessToken = nil
        isLoggedIn = false
        userCode = nil
        verificationUri = nil
        verificationUriComplete = nil
        profile = nil
        repos = []
        errorMessage = nil
        self.didOpenVerificationURL = false
        pollTimer?.invalidate()
        print("// MARK: - Logged out")
    }
}

// Helper: decode JSON with unknown types THE ANNOYING PART.
struct AnyDecodable: Decodable {
    let value: Any
    init<T>(_ value: T?) { self.value = value ?? () }
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let str = try? container.decode(String.self) {
            value = str
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let arr = try? container.decode([AnyDecodable].self) {
            value = arr.map { $0.value }
        } else if let dict = try? container.decode([String: AnyDecodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = ()
        }
    }
}
