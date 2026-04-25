//
//  RootView.swift
//  ICS
//
//  Created by Daddy on 19/04/2026.
//

import SwiftUI

struct RootView: View {
    
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        NavigationStack(path: $router.path) {
            
            Group {
                if auth.isLoggedIn {
                    CustomTabBar()
                } else {
                    LoginView()
                }
            }
            .navigationDestination(for: AppRouter.Route.self) { route in
                switch route {
                case .login:
                    LoginView()
                case .register:
                    RegisterView()
                case .home:
                    CustomTabBar()
                case .notification:
                    NotificationView()
                case .user:
                    UserView()
                case .chat:
                    DrChatView()
                case .sleepReport:
                    SleepReportView()
                case .tools:
                    ToolsView()
                case .analyze:
                    AnalyzeSleepView()
                }
            }
        }
    }
}
