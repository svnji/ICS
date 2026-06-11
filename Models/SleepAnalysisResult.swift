//
//  SleepAnalysisResult.swift
//  ICS
//

import Foundation

struct SleepAnalysisResult: Codable, Equatable {
    let sleepScore: Int
    let sleepQuality: String
    let totalSleepMinutes: Double
    let timeInBedMinutes: Double
    let sleepEfficiency: Double
    let deepSleepPct: Double
    let remSleepPct: Double
    let awakenings: Int
    let sleepLatencyMinutes: Double
    let stages: SleepStages
    let recommendations: [String]
}

struct SleepStages: Codable, Equatable {
    let awakeMins: Double
    let n1Mins: Double
    let n2Mins: Double
    let n3Mins: Double
    let remMins: Double

    var lightSleepMinutes: Double { n1Mins + n2Mins }
}

struct SleepAnalysisOutput: Equatable {
    let result: SleepAnalysisResult
    let stageTimeline: [String]
}

struct StoredSleepReport: Codable, Identifiable, Equatable {
    let id: UUID
    let analyzedAt: Date
    let sourceFileName: String
    let result: SleepAnalysisResult
    let stageTimeline: [String]

    init(
        id: UUID = UUID(),
        analyzedAt: Date = Date(),
        sourceFileName: String,
        result: SleepAnalysisResult,
        stageTimeline: [String]
    ) {
        self.id = id
        self.analyzedAt = analyzedAt
        self.sourceFileName = sourceFileName
        self.result = result
        self.stageTimeline = stageTimeline
    }
}

struct SleepStageTableRow: Identifiable {
    let id = UUID()
    let stage: String
    let iconName: String
    let iconColor: String
    let durationMinutes: Double
    let awakeEpisodeCount: Int
    let awakeTimeLabels: String
}

enum SleepReportPresentation {
    static let epochMinutes = 0.5

    static func formatDuration(_ minutes: Double) -> String {
        if minutes < 60 {
            return String(format: "%.0f min", minutes)
        }
        let hours = Int(minutes) / 60
        let mins = Int(minutes.rounded()) % 60
        if mins == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(mins)m"
    }

    static func formatClockTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    static func qualityBadge(for quality: String) -> String {
        switch quality {
        case "Good":
            return "GOOD"
        case "Fair":
            return "FAIR"
        default:
            return "BAD"
        }
    }

    static func qualityColor(for quality: String) -> String {
        switch quality {
        case "Good":
            return "green"
        case "Fair":
            return "orange"
        default:
            return "red"
        }
    }

    static func stageTableRows(for report: StoredSleepReport) -> [SleepStageTableRow] {
        let sessionStart = report.analyzedAt.addingTimeInterval(-report.result.timeInBedMinutes * 60)
        let episodes = awakeningEpisodes(in: report.stageTimeline, sessionStart: sessionStart)

        return [
            SleepStageTableRow(
                stage: "REM",
                iconName: "moon.fill",
                iconColor: "orange",
                durationMinutes: report.result.stages.remMins,
                awakeEpisodeCount: episodes.filter { $0.fromCategory == "REM" }.count,
                awakeTimeLabels: formattedTimes(episodes.filter { $0.fromCategory == "REM" }.map(\.time))
            ),
            SleepStageTableRow(
                stage: "Light",
                iconName: "moon.fill",
                iconColor: "lightBlue",
                durationMinutes: report.result.stages.lightSleepMinutes,
                awakeEpisodeCount: episodes.filter { $0.fromCategory == "Light" }.count,
                awakeTimeLabels: formattedTimes(episodes.filter { $0.fromCategory == "Light" }.map(\.time))
            ),
            SleepStageTableRow(
                stage: "Deep",
                iconName: "moon.fill",
                iconColor: "navy",
                durationMinutes: report.result.stages.n3Mins,
                awakeEpisodeCount: episodes.filter { $0.fromCategory == "Deep" }.count,
                awakeTimeLabels: formattedTimes(episodes.filter { $0.fromCategory == "Deep" }.map(\.time))
            ),
            SleepStageTableRow(
                stage: "Awake",
                iconName: "sun.max.fill",
                iconColor: "orange",
                durationMinutes: report.result.stages.awakeMins,
                awakeEpisodeCount: report.result.awakenings,
                awakeTimeLabels: formattedTimes(episodes.map(\.time))
            )
        ]
    }

    private struct AwakeningEpisode {
        let fromCategory: String
        let time: Date
    }

    private static func awakeningEpisodes(in stages: [String], sessionStart: Date) -> [AwakeningEpisode] {
        guard stages.count > 1 else { return [] }

        var episodes: [AwakeningEpisode] = []
        for index in 1..<stages.count where isAwake(stages[index]) && isSleepStage(stages[index - 1]) {
            let time = sessionStart.addingTimeInterval(Double(index) * epochMinutes * 60)
            episodes.append(
                AwakeningEpisode(
                    fromCategory: stageCategory(stages[index - 1]),
                    time: time
                )
            )
        }
        return episodes
    }

    private static func formattedTimes(_ dates: [Date]) -> String {
        guard !dates.isEmpty else { return "-" }
        return dates.map(formatClockTime).joined(separator: ", ")
    }

    static func isAwake(_ stage: String) -> Bool {
        let normalized = stage.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized == "W" || normalized.caseInsensitiveCompare("Awake") == .orderedSame
    }

    static func isSleepStage(_ stage: String) -> Bool {
        !isAwake(stage)
    }

    static func stageCategory(_ stage: String) -> String {
        if isAwake(stage) { return "Awake" }
        if stage == "N3" || stage.caseInsensitiveCompare("Deep") == .orderedSame { return "Deep" }
        if stage == "REM" { return "REM" }
        return "Light"
    }

    static func hypnogramLabels(for stages: [String], maxLabels: Int = 6) -> [String] {
        guard !stages.isEmpty else { return [] }

        var regions: [(label: String, length: Int)] = []
        var currentCategory = stageCategory(stages[0])
        var currentLength = 1

        for stage in stages.dropFirst() {
            let category = stageCategory(stage)
            if category == currentCategory {
                currentLength += 1
            } else {
                regions.append((displayLabel(for: currentCategory), currentLength))
                currentCategory = category
                currentLength = 1
            }
        }
        regions.append((displayLabel(for: currentCategory), currentLength))

        if regions.count <= maxLabels {
            return regions.map(\.label)
        }

        var merged: [(label: String, length: Int)] = []
        let chunkSize = max(1, regions.count / maxLabels)
        var index = 0
        while index < regions.count {
            let end = min(index + chunkSize, regions.count)
            let chunk = regions[index..<end]
            let dominant = chunk.max(by: { $0.length < $1.length })?.label ?? chunk.first?.label ?? "Light"
            merged.append((dominant, chunk.reduce(0) { $0 + $1.length }))
            index = end
        }
        return merged.map(\.label)
    }

    private static func displayLabel(for category: String) -> String {
        switch category {
        case "Awake":
            return "Awake"
        case "Deep":
            return "Deep"
        case "REM":
            return "REM"
        default:
            return "Light"
        }
    }
}
