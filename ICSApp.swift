//
//  ICSApp.swift
//  ICS
//
//  Created by Daddy on 19/04/2026.
//

import SwiftUI
import Firebase

@main
struct ICSApp: App {
    
    @StateObject private var auth = AuthManager.shared
    @StateObject private var router = AppRouter()
    @StateObject private var sleepReportStore = SleepReportStore()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(router)
                .environmentObject(sleepReportStore)
        }
    }
}
