//
//  SleepReportUI.swift
//  ICS
//

import SwiftUI

enum SleepTheme {
    static let navy = Color(red: 0.08, green: 0.18, blue: 0.42)
    static let skyTop = Color(red: 0.94, green: 0.97, blue: 1.0)
    static let skyBottom = Color(red: 0.88, green: 0.94, blue: 1.0)
    static let cardFill = Color.white.opacity(0.96)
    static let cardBorder = Color(red: 0.78, green: 0.88, blue: 0.98)
    static let metricBlue = Color(red: 0.18, green: 0.42, blue: 0.82)
    static let lightBlue = Color(red: 0.55, green: 0.76, blue: 0.95)
    static let deepBlue = Color(red: 0.20, green: 0.34, blue: 0.72)
    static let accentYellow = Color(red: 1.0, green: 0.82, blue: 0.18)
    static let scoreTeal = Color(red: 0.18, green: 0.72, blue: 0.78)
    static let scoreGreen = Color(red: 0.34, green: 0.82, blue: 0.52)
}

struct LastSleepAnalysisCard: View {
    let report: StoredSleepReport

    private var result: SleepAnalysisResult { report.result }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Last Sleep Analysis")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(SleepTheme.navy)

            HStack(alignment: .top, spacing: 8) {
                summaryMetric(
                    icon: "bed.double.fill",
                    iconColor: SleepTheme.metricBlue,
                    value: SleepReportPresentation.formatDuration(result.totalSleepMinutes),
                    label: "Sleep"
                )

                qualityMetric

                summaryMetric(
                    icon: "bell.fill",
                    iconColor: SleepTheme.accentYellow,
                    value: "\(result.awakenings)x",
                    label: "Awakenings"
                )
            }

            HStack(spacing: 8) {
                Image(systemName: "stopwatch.fill")
                    .foregroundStyle(SleepTheme.accentYellow)
                    .font(.system(size: 18, weight: .semibold))
                Text("\(SleepReportPresentation.formatDuration(result.sleepLatencyMinutes)) Latency")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SleepTheme.navy)
            }

            SleepHypnogramView(stages: report.stageTimeline)
                .frame(height: 72)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [SleepTheme.skyTop, SleepTheme.skyBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(SleepTheme.cardBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    private var qualityMetric: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [SleepTheme.scoreTeal, SleepTheme.scoreGreen, SleepTheme.scoreTeal],
                            center: .center
                        ),
                        lineWidth: 5
                    )
                    .frame(width: 58, height: 58)

                Circle()
                    .fill(SleepTheme.navy)
                    .frame(width: 42, height: 42)
                    .overlay {
                        Image(systemName: "moon.stars.fill")
                            .foregroundStyle(SleepTheme.accentYellow)
                            .font(.system(size: 16))
                    }
            }

            Text("\(result.sleepScore)% \(result.sleepQuality)")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(SleepTheme.navy)
                .multilineTextAlignment(.center)

            Text("Sleep Quality")
                .font(.caption)
                .foregroundStyle(SleepTheme.navy.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
    }

    private func summaryMetric(
        icon: String,
        iconColor: Color,
        value: String,
        label: String
    ) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.system(size: 22, weight: .semibold))

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(SleepTheme.navy)
                .multilineTextAlignment(.center)

            Text(label)
                .font(.caption)
                .foregroundStyle(SleepTheme.navy.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
    }
}

struct SleepHypnogramView: View {
    let stages: [String]

    private var labels: [String] {
        SleepReportPresentation.hypnogramLabels(for: stages)
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.90, green: 0.95, blue: 1.0),
                                    Color(red: 0.82, green: 0.91, blue: 0.99)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    hypnogramPath(in: geometry.size)
                        .stroke(SleepTheme.metricBlue, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    if let peak = peakPoint(in: geometry.size) {
                        Circle()
                            .fill(SleepTheme.accentYellow)
                            .frame(width: 10, height: 10)
                            .overlay {
                                Circle()
                                    .stroke(SleepTheme.accentYellow.opacity(0.35), lineWidth: 6)
                            }
                            .position(peak)
                    }
                }
            }

            if !labels.isEmpty {
                HStack {
                    ForEach(Array(labels.enumerated()), id: \.offset) { _, label in
                        Text(label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(SleepTheme.navy.opacity(0.8))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func hypnogramPath(in size: CGSize) -> Path {
        var path = Path()
        guard stages.count > 1 else { return path }

        let stepX = size.width / CGFloat(max(stages.count - 1, 1))
        let points = stages.enumerated().map { index, stage in
            CGPoint(x: CGFloat(index) * stepX, y: yPosition(for: stage, height: size.height))
        }

        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        return path
    }

    private func peakPoint(in size: CGSize) -> CGPoint? {
        guard stages.count > 1 else { return nil }

        let stepX = size.width / CGFloat(max(stages.count - 1, 1))
        guard let peakIndex = stages.enumerated().max(by: { yRank($0.element) < yRank($1.element) })?.offset else {
            return nil
        }

        return CGPoint(
            x: CGFloat(peakIndex) * stepX,
            y: yPosition(for: stages[peakIndex], height: size.height)
        )
    }

    private func yPosition(for stage: String, height: CGFloat) -> CGFloat {
        let padding = height * 0.12
        let usable = height - padding * 2
        return padding + usable * yRank(stage)
    }

    private func yRank(_ stage: String) -> CGFloat {
        switch SleepReportPresentation.stageCategory(stage) {
        case "Awake":
            return 0.08
        case "Light":
            return 0.35
        case "REM":
            return 0.58
        case "Deep":
            return 0.88
        default:
            return 0.35
        }
    }
}

struct SleepReportDetailView: View {
    let report: StoredSleepReport

    private var result: SleepAnalysisResult { report.result }
    private var rows: [SleepStageTableRow] { SleepReportPresentation.stageTableRows(for: report) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                stagesCard
                summaryCard
                recommendationsCard
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
        .background(
            LinearGradient(
                colors: [SleepTheme.skyTop, SleepTheme.skyBottom, .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private var header: some View {
        HStack(alignment: .top) {
            Text("Sleep Report")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(SleepTheme.navy)

            Spacer()

            Image("owl with red funny eyes 1-020")
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 92)
        }
        .padding(.top, 8)
    }

    private var stagesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Stages")
                .font(.headline)
                .foregroundStyle(SleepTheme.navy)

            VStack(spacing: 0) {
                HStack {
                    tableHeader("Stage")
                    tableHeader("Time")
                    tableHeader("Awake Times")
                    tableHeader("Awake Time")
                }
                .padding(.vertical, 10)
                .background(Color(red: 0.90, green: 0.95, blue: 1.0))

                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    HStack(alignment: .center) {
                        HStack(spacing: 8) {
                            stageIcon(for: row)
                            Text(row.stage)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SleepTheme.navy)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(SleepReportPresentation.formatDuration(row.durationMinutes))
                            .frame(maxWidth: .infinity)

                        Text("\(row.awakeEpisodeCount)")
                            .frame(maxWidth: .infinity)

                        Text(row.awakeTimeLabels)
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                    .background(index.isMultiple(of: 2) ? Color.white : Color(red: 0.95, green: 0.98, blue: 1.0))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(SleepTheme.cardBorder, lineWidth: 1)
            )
        }
        .padding(16)
        .background(cardBackground)
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(SleepTheme.lightBlue.opacity(0.35), lineWidth: 6)
                        .frame(width: 64, height: 64)

                    Circle()
                        .trim(from: 0, to: CGFloat(result.sleepScore) / 100)
                        .stroke(
                            AngularGradient(
                                colors: [SleepTheme.scoreTeal, SleepTheme.scoreGreen],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 64, height: 64)

                    Text("\(result.sleepScore)%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SleepTheme.navy)
                }

                Text(SleepReportPresentation.qualityBadge(for: result.sleepQuality))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(qualityBadgeColor)
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 72)

            VStack(spacing: 8) {
                Image(systemName: "stopwatch.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                Text(SleepReportPresentation.formatDuration(result.sleepLatencyMinutes))
                    .font(.headline)
                    .foregroundStyle(SleepTheme.navy)
                Text("Sleep Latency:")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 72)

            VStack(spacing: 8) {
                Image(systemName: "bed.double.fill")
                    .foregroundStyle(SleepTheme.metricBlue)
                    .font(.title3)
                Text(SleepReportPresentation.formatDuration(result.totalSleepMinutes))
                    .font(.headline)
                    .foregroundStyle(SleepTheme.navy)
                Text("Total Sleep:")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .background(cardBackground)
    }

    private var recommendationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
                .foregroundStyle(SleepTheme.navy)

            HStack(alignment: .top, spacing: 12) {
                Image("sleepy owl  1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 92, height: 92)

                Text(recommendationsText)
                    .font(.subheadline)
                    .foregroundStyle(SleepTheme.navy.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private var recommendationsText: AttributedString {
        var text = AttributedString(
            result.recommendations.joined(separator: " ")
        )

        if result.sleepQuality != "Good" {
            text = AttributedString(
                "Your sleep quality was not optimal. We recommend reading our article "
            )
            var link = AttributedString("Better Sleep Tips")
            link.foregroundColor = SleepTheme.metricBlue
            link.underlineStyle = .single
            text.append(link)
            text.append(AttributedString(" for helpful advice to improve your sleep. "))
            if let first = result.recommendations.first {
                text.append(AttributedString(first))
            }
        }

        return text
    }

    private var qualityBadgeColor: Color {
        switch result.sleepQuality {
        case "Good":
            return .green
        case "Fair":
            return .orange
        default:
            return .red
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(SleepTheme.cardFill)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(SleepTheme.cardBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }

    private func tableHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(SleepTheme.navy)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func stageIcon(for row: SleepStageTableRow) -> some View {
        switch row.iconColor {
        case "orange":
            Image(systemName: row.iconName)
                .foregroundStyle(.orange)
        case "navy":
            Image(systemName: row.iconName)
                .foregroundStyle(SleepTheme.deepBlue)
        default:
            Image(systemName: row.iconName)
                .foregroundStyle(SleepTheme.lightBlue)
        }
    }
}

struct SleepReportEmptyState: View {
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 42))
                .foregroundStyle(SleepTheme.metricBlue)

            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(SleepTheme.navy)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(SleepTheme.metricBlue)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [SleepTheme.skyTop, SleepTheme.skyBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(SleepTheme.cardBorder, lineWidth: 1)
        )
    }
}

#Preview("Last Sleep Card") {
    LastSleepAnalysisCard(
        report: StoredSleepReport(
            sourceFileName: "sample.csv",
            result: SleepAnalysisResult(
                sleepScore: 82,
                sleepQuality: "Good",
                totalSleepMinutes: 444,
                timeInBedMinutes: 470,
                sleepEfficiency: 87.5,
                deepSleepPct: 18,
                remSleepPct: 22,
                awakenings: 2,
                sleepLatencyMinutes: 26,
                stages: SleepStages(
                    awakeMins: 26,
                    n1Mins: 30,
                    n2Mins: 210,
                    n3Mins: 85,
                    remMins: 89
                ),
                recommendations: ["Your sleep was healthy and restorative."]
            ),
            stageTimeline: Array(repeating: "N2", count: 40)
        )
    )
    .padding()
}
