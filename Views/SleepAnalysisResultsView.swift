//
//  SleepAnalysisResultsView.swift
//  ICS
//

import SwiftUI

struct SleepAnalysisResultsView: View {
    let result: SleepAnalysisResult

    private var scoreColor: Color {
        switch result.sleepQuality {
        case "Good":
            return .green
        case "Fair":
            return .orange
        default:
            return .red
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                scoreSection
                metricsGrid
                stageBar
                recommendationsSection
            }
            .padding()
        }
        .navigationTitle("Sleep Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var scoreSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.2), lineWidth: 14)
                    .frame(width: 150, height: 150)

                Circle()
                    .trim(from: 0, to: CGFloat(result.sleepScore) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 150, height: 150)

                Text("\(result.sleepScore)")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(scoreColor)
            }

            Text("\(result.sleepQuality) Sleep Quality")
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var metricsGrid: some View {
        let metrics: [(String, String)] = [
            ("Total Sleep", formatDuration(result.totalSleepMinutes)),
            ("Time in Bed", formatDuration(result.timeInBedMinutes)),
            ("Sleep Efficiency", String(format: "%.1f%%", result.sleepEfficiency)),
            ("Deep Sleep", String(format: "%.1f%%", result.deepSleepPct)),
            ("REM Sleep", String(format: "%.1f%%", result.remSleepPct)),
            ("Awakenings", "\(result.awakenings)"),
            ("Sleep Latency", String(format: "%.1f min", result.sleepLatencyMinutes))
        ]

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                metricCard(title: metric.0, value: metric.1)
            }
        }
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var stageBar: some View {
        let segments: [(String, Double, Color)] = [
            ("Awake", result.stages.awakeMins, .red),
            ("N1", result.stages.n1Mins, Color(red: 0.68, green: 0.85, blue: 0.95)),
            ("N2", result.stages.n2Mins, Color(red: 0.40, green: 0.67, blue: 0.87)),
            ("N3", result.stages.n3Mins, Color(red: 0.25, green: 0.32, blue: 0.71)),
            ("REM", result.stages.remMins, .purple)
        ]

        let total = segments.reduce(0) { $0 + $1.1 }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Stages")
                .font(.headline)

            if total > 0 {
                GeometryReader { geometry in
                    HStack(spacing: 2) {
                        ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                            if segment.1 > 0 {
                                segment.2
                                    .frame(width: max(4, geometry.size.width * CGFloat(segment.1 / total)))
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(height: 28)

                HStack(alignment: .top, spacing: 8) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(segment.2)
                                .frame(width: 8, height: 8)
                            Text(segment.0)
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(formatDuration(segment.1))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            } else {
                Text("No stage data available.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)

            ForEach(Array(result.recommendations.enumerated()), id: \.offset) { _, recommendation in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.body)
                    Text(recommendation)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func formatDuration(_ minutes: Double) -> String {
        if minutes < 60 {
            return String(format: "%.0f min", minutes)
        }
        let hours = Int(minutes) / 60
        let mins = Int(minutes.rounded()) % 60
        return "\(hours)h \(mins)m"
    }
}

#Preview {
    NavigationStack {
        SleepAnalysisResultsView(
            result: SleepAnalysisResult(
                sleepScore: 82,
                sleepQuality: "Good",
                totalSleepMinutes: 420,
                timeInBedMinutes: 480,
                sleepEfficiency: 87.5,
                deepSleepPct: 18,
                remSleepPct: 22,
                awakenings: 2,
                sleepLatencyMinutes: 12,
                stages: SleepStages(
                    awakeMins: 60,
                    n1Mins: 30,
                    n2Mins: 210,
                    n3Mins: 75,
                    remMins: 105
                ),
                recommendations: [
                    "Your sleep was healthy and restorative. Keep up your current habits."
                ]
            )
        )
    }
}
