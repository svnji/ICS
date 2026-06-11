//
//  HomeView.swift
//  ICS
//
//  Created by Daddy on 19/04/2026.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var sleepReportStore: SleepReportStore
    @EnvironmentObject var tabBarViewModel: CustomTabBarViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // MARK: - Nav Bar
                HStack(spacing: 10) {
                    Image("image 7-018")
                        .resizable()
                        .scaledToFit()
                    
                    Spacer()
                    
                    Button {
                        router.goTo(.notification)
                    } label: {
                        VStack {
                            Image(systemName: "bell")
                                .font(.system(size: 20))
                            Text("Notifications")
                                .font(.caption)
                        }
                    }
                    
                    Button { } label: {
                        VStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20))
                            Text("Search")
                                .font(.caption)
                        }
                    }
                    
                    Button { } label: {
                        VStack {
                            Image(systemName: "pencil.and.list.clipboard")
                                .font(.system(size: 20))
                            Text("Write Report")
                                .font(.caption)
                        }
                    }
                    
                    Button {
                        router.goTo(.user)
                    } label: {
                        VStack {
                            Image(systemName: "person")
                                .font(.system(size: 20))
                            Text("User")
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal)
                .frame(height: 100)
                
                // MARK: - Last Sleep Analysis
                Group {
                    if let report = sleepReportStore.lastReport {
                        LastSleepAnalysisCard(report: report)
                            .padding(.horizontal)
                            .onTapGesture {
                                tabBarViewModel.index = 1
                            }
                    } else {
                        SleepReportEmptyState(
                            title: "Last Sleep Analysis",
                            message: "Analyze your sleep to see your latest report here.",
                            actionTitle: "Analyze Sleep"
                        ) {
                            tabBarViewModel.index = 4
                        }
                        .padding(.horizontal)
                    }
                }
                
                // MARK: - Community Blogs
                VStack(alignment: .leading, spacing: 8) {
                    Text("Blogs from other users")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Image("4.blogs from othoer owls-Photoroom 1-017")
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                }
                
                // MARK: - Dr. Owl Blogs
                VStack(alignment: .leading, spacing: 8) {
                    Text("Blogs and tips from Dr. Owl")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Image("5.dr owl blogs 1-009")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                }
                
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppRouter())
        .environmentObject(SleepReportStore())
        .environmentObject(CustomTabBarViewModel())
}
