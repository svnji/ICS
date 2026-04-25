//
//  AppRouter.swift
//  ICS
//
//  Created by Daddy on 19/04/2026.
//

import SwiftUI

final class AppRouter: ObservableObject {
    
    enum Route: Hashable {
        case login
        case register
        case home
        case notification
        case user
        case chat
        case sleepReport
        case tools
        case analyze
    }
    
    @Published var path: [Route] = []
    
    func goTo(_ route: Route) {
        path.append(route)
    }
    
    func resetToRoot(_ route: Route) {
        path = [route]
    }
    
    func pop() {
        _ = path.popLast()
    }
    
    func popToRoot() {
        path.removeAll()
    }
}
