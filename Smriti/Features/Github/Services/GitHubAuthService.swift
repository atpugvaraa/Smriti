//
//  GitHubAuthService.swift
//  Smriti
//
//  Created by Aarav Gupta on 19/06/25.
//

import Foundation
import UIKit

@Observable
final class GitHubAuthService {
    static let shared = GitHubAuthService()

    // MARK: - Public State
    var isLoggedIn: Bool = false
    var isWaiting: Bool = false
    var errorMessage: String?

    var userCode: String?
    var verificationUri: String?
    var verificationUriComplete: String?
    var didOpenVerificationURL: Bool = false

    // MARK: - Private
    private let accessTokenKey = "GitHubAccessToken"
    private var deviceCode: String?
    private var pollInterval: Int = 5
    private var pollTimer: Timer?

    private let clientID = Secrets.githubClientID

    var accessToken: String? {
        didSet {
            if let token = accessToken {
                UserDefaults.standard.set(token, forKey: accessTokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: accessTokenKey)
            }
        }
    }

    private init() {
        accessToken = UserDefaults.standard.string(forKey: accessTokenKey)
        isLoggedIn = accessToken != nil
    }

    func startDeviceFlow() {
        guard let url = URL(string: "https://github.com/login/device/code") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "client_id=\(clientID)&scope=repo%20read:user".data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        isWaiting = true
        errorMessage = nil

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                guard error == nil, let data = data else {
                    self.errorMessage = error?.localizedDescription ?? "No data returned."
                    self.isWaiting = false
                    return
                }

                let text = String(data: data, encoding: .utf8) ?? ""
                let pairs = text.split(separator: "&")
                var dict: [String: String] = [:]
                for pair in pairs {
                    let parts = pair.split(separator: "=", maxSplits: 1).map { String($0) }
                    if parts.count == 2 {
                        dict[parts[0]] = parts[1].removingPercentEncoding ?? parts[1]
                    }
                }

                self.userCode = dict["user_code"]
                self.verificationUri = dict["verification_uri"]
                self.verificationUriComplete = dict["verification_uri_complete"]
                self.deviceCode = dict["device_code"]
                self.pollInterval = Int(dict["interval"] ?? "5") ?? 5

                if let uri = self.verificationUri, let url = URL(string: uri), !self.didOpenVerificationURL {
                    UIApplication.shared.open(url)
                    self.didOpenVerificationURL = true
                }

                self.startPollingForToken()
            }
        }.resume()
    }

    func startPollingForToken() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(pollInterval), repeats: true) { [weak self] _ in
            self?.pollForAccessToken()
        }
    }

    private func pollForAccessToken() {
        guard let deviceCode else { return }

        let url = URL(string: "https://github.com/login/oauth/access_token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "client_id=\(clientID)&device_code=\(deviceCode)&grant_type=urn:ietf:params:oauth:grant-type:device_code"
            .data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                guard error == nil, let data = data else {
                    self.errorMessage = error?.localizedDescription ?? "No data returned."
                    self.isWaiting = false
                    self.pollTimer?.invalidate()
                    return
                }

                do {
                    let response = try JSONDecoder().decode(GitHubAccessTokenResponse.self, from: data)
                    if let token = response.access_token {
                        self.accessToken = token
                        self.isLoggedIn = true
                        self.isWaiting = false
                        self.pollTimer?.invalidate()
                    } else if let errorType = response.error {
                        switch errorType {
                        case "authorization_pending":
                            break // keep polling
                        case "slow_down":
                            self.pollInterval += 5
                            self.startPollingForToken()
                        default:
                            self.errorMessage = response.error_description ?? "Unknown error"
                            self.pollTimer?.invalidate()
                        }
                    }
                } catch {
                    self.errorMessage = "Decode error: \(error.localizedDescription)"
                    self.pollTimer?.invalidate()
                }
            }
        }.resume()
    }

    func logout() {
        accessToken = nil
        isLoggedIn = false
        userCode = nil
        verificationUri = nil
        verificationUriComplete = nil
        errorMessage = nil
        didOpenVerificationURL = false
        pollTimer?.invalidate()
    }
}
