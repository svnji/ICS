//
//  SleepReportView.swift
//  ICS
//
//  Created by Daddy on 20/04/2026.
//

import SwiftUI

struct SleepReportView: View {
    @EnvironmentObject var sleepReportStore: SleepReportStore
    @EnvironmentObject var tabBarViewModel: CustomTabBarViewModel

    var body: some View {
        Group {
            if let report = sleepReportStore.lastReport {
                SleepReportDetailView(report: report)
            } else {
                VStack {
                    SleepReportEmptyState(
                        title: "Sleep Report",
                        message: "No sleep report yet. Run an analysis to generate your first report.",
                        actionTitle: "Analyze Sleep"
                    ) {
                        tabBarViewModel.index = 4
                    }
                    .padding()

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        colors: [SleepTheme.skyTop, SleepTheme.skyBottom, .white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
            }
        }
    }
}

#Preview {
    SleepReportView()
        .environmentObject(SleepReportStore())
        .environmentObject(CustomTabBarViewModel())
}
