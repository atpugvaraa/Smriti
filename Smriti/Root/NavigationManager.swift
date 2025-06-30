//
//  NavigationManager.swift
//  Smriti
//
//  Created by Aarav Gupta on 20/06/25.
//

import SwiftUI

enum AppRoute: Hashable {
    case noteDetail(SmritiNote)
//    case repoDetail(GitHubRepo)
    // Add more routes here as needed
}

@Observable
final class NavigationManager {
    static let shared = NavigationManager()
    
    var path = NavigationPath()
    
    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}
