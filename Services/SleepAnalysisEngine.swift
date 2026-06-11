//
//  SleepAnalysisEngine.swift
//  ICS
//

import CoreML
import Foundation

enum SleepAnalysisError: LocalizedError {
    case fileUnreadable
    case emptyDataset
    case missingFeatureColumn(String)
    case invalidFeatureValue(String)
    case modelUnavailable

    var errorDescription: String? {
        switch self {
        case .fileUnreadable:
            return "Could not read the selected CSV file."
        case .emptyDataset:
            return "The CSV file contains no data rows."
        case .missingFeatureColumn(let name):
            return "Missing required column: \(name)"
        case .invalidFeatureValue(let detail):
            return "Invalid feature value: \(detail)"
        case .modelUnavailable:
            return "Sleep stage model is not available in the app bundle."
        }
    }
}

final class SleepAnalysisEngine {

    /// Must match feature_columns printed by convert_to_coreml.py
    static let featureColumns = ["EEG"]
    static let bundledSampleName = "my_EEG_healthy_sleep_8h_epochs"
    static let bundledRawSampleName = "my_EEG_healthy_sleep_8h"

    private let epochMinutes = 0.5
    private let downsampleStep = 10
    private let samplesPerEpoch = 100 * 30
    private let stageLabels: [String]

    init() {
        if let url = Bundle.main.url(forResource: "label_classes", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let labels = try? JSONDecoder().decode([String].self, from: data) {
            stageLabels = labels
        } else {
            stageLabels = ["Awake", "N1", "N2", "N3", "REM"]
        }
    }

    static func bundledSampleURL() -> URL? {
        if let epochs = Bundle.main.url(forResource: bundledSampleName, withExtension: "csv") {
            return epochs
        }
        return Bundle.main.url(forResource: bundledRawSampleName, withExtension: "csv")
    }

    func analyze(fileURL: URL) throws -> SleepAnalysisOutput {
        let stages = try streamPredictions(from: fileURL)
        guard !stages.isEmpty else {
            throw SleepAnalysisError.emptyDataset
        }
        return SleepAnalysisOutput(
            result: buildResult(from: stages),
            stageTimeline: stages
        )
    }

    // MARK: - Streaming CSV + inference

    private func streamPredictions(from fileURL: URL) throws -> [String] {
        let isSecurityScoped = fileURL.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        let handle = try FileHandle(forReadingFrom: fileURL)
        defer {
            try? handle.close()
        }

        guard let headerLine = readLine(from: handle) else {
            throw SleepAnalysisError.emptyDataset
        }

        let headers = parseCSVLine(headerLine)
        let columnIndex = Dictionary(uniqueKeysWithValues: headers.enumerated().map { ($1, $0) })

        guard let eegIndex = columnIndex["EEG"] else {
            throw SleepAnalysisError.missingFeatureColumn("EEG")
        }

        let isRawHighFrequency = columnIndex["Timestamp"] != nil
        let model = try SleepStageClassifier(configuration: MLModelConfiguration())

        var stages: [String] = []

        if isRawHighFrequency {
            var rawSampleIndex = 0
            var epochBuffer: [Double] = []
            epochBuffer.reserveCapacity(samplesPerEpoch)

            while let line = readLine(from: handle) {
                let values = parseCSVLine(line)
                guard eegIndex < values.count,
                      let eeg = parseDouble(values[eegIndex]) else {
                    continue
                }

                if rawSampleIndex % downsampleStep == 0 {
                    epochBuffer.append(eeg)
                    if epochBuffer.count == samplesPerEpoch {
                        let mean = epochBuffer.reduce(0, +) / Double(epochBuffer.count)
                        stages.append(try predictStage(eeg: mean, model: model))
                        epochBuffer.removeAll(keepingCapacity: true)
                    }
                }

                rawSampleIndex += 1
            }
        } else {
            while let line = readLine(from: handle) {
                let values = parseCSVLine(line)
                guard eegIndex < values.count,
                      let eeg = parseDouble(values[eegIndex]) else {
                    continue
                }
                stages.append(try predictStage(eeg: eeg, model: model))
            }
        }

        return stages
    }

    private func readLine(from handle: FileHandle) -> String? {
        var bytes = Data()

        while true {
            let chunk = handle.readData(ofLength: 1)
            if chunk.isEmpty {
                guard !bytes.isEmpty else { return nil }
                return String(data: bytes, encoding: .utf8)?
                    .trimmingCharacters(in: .newlines)
            }

            let byte = chunk[chunk.startIndex]
            if byte == 10 {
                guard !bytes.isEmpty else { continue }
                return String(data: bytes, encoding: .utf8)?
                    .trimmingCharacters(in: .newlines)
            }

            if byte != 13 {
                bytes.append(byte)
            }
        }
    }

    private func parseCSVLine(_ line: String) -> [String] {
        line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
    }

    private func parseDouble(_ raw: String) -> Double? {
        Double(raw.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // MARK: - Core ML

    private func predictStage(eeg: Double, model: SleepStageClassifier) throws -> String {
        let output = try model.prediction(EEG: eeg)
        return normalizeStageLabel(output.predicted_stage)
    }

    private func normalizeStageLabel(_ raw: String) -> String {
        raw
    }

    private func normalizeStageLabel(_ raw: Int) -> String {
        guard raw >= 0, raw < stageLabels.count else { return String(raw) }
        return stageLabels[raw]
    }

    private func normalizeStageLabel(_ raw: Int64) -> String {
        normalizeStageLabel(Int(raw))
    }

    private func normalizeStageLabel(_ raw: Double) -> String {
        let index = Int(raw.rounded())
        guard index >= 0, index < stageLabels.count else { return String(raw) }
        return stageLabels[index]
    }

    // MARK: - Metrics

    private func buildResult(from stages: [String]) -> SleepAnalysisResult {
        let awakeCount = stages.filter(isAwake).count
        let n1Count = stages.filter { $0 == "N1" }.count
        let n2Count = stages.filter { $0 == "N2" }.count
        let n3Count = stages.filter { isDeepSleep($0) }.count
        let remCount = stages.filter { $0 == "REM" }.count

        let awakeMins = Double(awakeCount) * epochMinutes
        let n1Mins = Double(n1Count) * epochMinutes
        let n2Mins = Double(n2Count) * epochMinutes
        let n3Mins = Double(n3Count) * epochMinutes
        let remMins = Double(remCount) * epochMinutes

        let totalSleep = n1Mins + n2Mins + n3Mins + remMins
        let timeInBed = Double(stages.count) * epochMinutes
        let sleepEfficiency = timeInBed > 0 ? (totalSleep / timeInBed) * 100 : 0
        let deepSleepPct = totalSleep > 0 ? (n3Mins / totalSleep) * 100 : 0
        let remSleepPct = totalSleep > 0 ? (remMins / totalSleep) * 100 : 0
        let awakenings = countAwakenings(in: stages)
        let sleepLatency = computeSleepLatency(in: stages)

        let sleepScore = computeSleepScore(
            efficiency: sleepEfficiency,
            deepPct: deepSleepPct,
            remPct: remSleepPct,
            awakenings: awakenings
        )
        let sleepQuality = qualityLabel(for: sleepScore)
        let recommendations = buildRecommendations(
            deepPct: deepSleepPct,
            remPct: remSleepPct,
            efficiency: sleepEfficiency,
            awakenings: awakenings
        )

        return SleepAnalysisResult(
            sleepScore: sleepScore,
            sleepQuality: sleepQuality,
            totalSleepMinutes: totalSleep,
            timeInBedMinutes: timeInBed,
            sleepEfficiency: sleepEfficiency,
            deepSleepPct: deepSleepPct,
            remSleepPct: remSleepPct,
            awakenings: awakenings,
            sleepLatencyMinutes: sleepLatency,
            stages: SleepStages(
                awakeMins: awakeMins,
                n1Mins: n1Mins,
                n2Mins: n2Mins,
                n3Mins: n3Mins,
                remMins: remMins
            ),
            recommendations: recommendations
        )
    }

    private func isAwake(_ stage: String) -> Bool {
        let normalized = stage.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized == "W" || normalized.caseInsensitiveCompare("Awake") == .orderedSame
    }

    private func isDeepSleep(_ stage: String) -> Bool {
        let normalized = stage.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized == "N3" || normalized.caseInsensitiveCompare("Deep") == .orderedSame
    }

    private func isSleepStage(_ stage: String) -> Bool {
        !isAwake(stage)
    }

    private func countAwakenings(in stages: [String]) -> Int {
        guard stages.count > 1 else { return 0 }

        var count = 0
        for index in 1..<stages.count {
            if isAwake(stages[index]) && isSleepStage(stages[index - 1]) {
                count += 1
            }
        }
        return count
    }

    private func computeSleepLatency(in stages: [String]) -> Double {
        guard let firstSleepIndex = stages.firstIndex(where: { isSleepStage($0) }) else {
            return timeInBedMinutes(for: stages.count)
        }
        return Double(firstSleepIndex) * epochMinutes
    }

    private func timeInBedMinutes(for epochCount: Int) -> Double {
        Double(epochCount) * epochMinutes
    }

    private func computeSleepScore(
        efficiency: Double,
        deepPct: Double,
        remPct: Double,
        awakenings: Int
    ) -> Int {
        var score = 50

        if efficiency > 85 {
            score += 15
        }
        if deepPct >= 13 && deepPct <= 23 {
            score += 15
        }
        if remPct >= 20 && remPct <= 25 {
            score += 10
        }
        if awakenings <= 2 {
            score += 10
        }

        return min(score, 100)
    }

    private func qualityLabel(for score: Int) -> String {
        switch score {
        case 80...100:
            return "Good"
        case 60...79:
            return "Fair"
        default:
            return "Poor"
        }
    }

    private func buildRecommendations(
        deepPct: Double,
        remPct: Double,
        efficiency: Double,
        awakenings: Int
    ) -> [String] {
        var items: [String] = []

        if deepPct < 13 {
            items.append("Deep sleep is below recommended. Try regular exercise and reducing stress.")
        }
        if remPct < 20 {
            items.append("REM sleep is low. Avoid alcohol and maintain a consistent sleep schedule.")
        }
        if efficiency < 85 {
            items.append("Sleep efficiency is low. Avoid screens before bed and keep a fixed wake time.")
        }
        if awakenings > 2 {
            items.append("Multiple awakenings detected. Reduce caffeine and optimize your sleep environment.")
        }
        if items.isEmpty {
            items.append("Your sleep was healthy and restorative. Keep up your current habits.")
        }

        return items
    }
}
