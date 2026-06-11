//
//  AnalyzeSleepView.swift
//  ICS
//
//  Created by Daddy on 20/04/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct AnalyzeSleepView: View {

    @EnvironmentObject var sleepReportStore: SleepReportStore
    @State private var isShowingFilePicker = false
    @State private var selectedFileURL: URL?
    @State private var selectedFileName = ""
    @State private var isAnalyzing = false
    @State private var analysisResult: SleepAnalysisResult?
    @State private var errorMessage: String?
    @State private var showResults = false
    @State private var statusMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
//                Image("image-Photoroom (7) 1-021")
//                    .resizable()
//                    .scaledToFit()
//                    .padding(.horizontal)

                uploadSection
            }
            .padding(.bottom, 100)
        }
        .onAppear {
            loadBundledSampleIfNeeded()
        }
        .task(id: selectedFileURL) {
            guard selectedFileURL != nil, analysisResult == nil, !isAnalyzing else { return }
            runAnalysis()
        }
        .sheet(isPresented: $showResults) {
            if let analysisResult {
                NavigationStack {
                    SleepAnalysisResultsView(result: analysisResult)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { showResults = false }
                            }
                        }
                }
            }
        }
        .alert("Analysis Failed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    private var uploadSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upload file to analyze your sleep")
                .font(.headline)
                .padding(.horizontal)

            Text("Raw EEG files (with Timestamp + EEG) are converted on-device into 30-second epochs automatically.")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal)

            VStack(spacing: 12) {
                if isAnalyzing {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text(statusMessage.isEmpty ? "Analyzing sleep data..." : statusMessage)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                if !selectedFileName.isEmpty {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                        Text(selectedFileName)
                            .font(.subheadline)
                            .lineLimit(2)
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    isShowingFilePicker = true
                } label: {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Choose Different CSV File")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .fileImporter(
                    isPresented: $isShowingFilePicker,
                    allowedContentTypes: [.commaSeparatedText, .plainText, .data],
                    allowsMultipleSelection: false
                ) { result in
                    handleFileSelection(result)
                }

                Button {
                    analysisResult = nil
                    showResults = false
                    runAnalysis()
                } label: {
                    HStack(spacing: 10) {
                        if isAnalyzing {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isAnalyzing ? "Analyzing..." : "Analyze Again")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedFileURL == nil || isAnalyzing ? Color.gray : Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(selectedFileURL == nil || isAnalyzing)
            }
            .padding(.horizontal)
        }
    }

    private func loadBundledSampleIfNeeded() {
        guard selectedFileURL == nil,
              let url = SleepAnalysisEngine.bundledSampleURL() else {
            return
        }

        selectedFileURL = url
        if url.lastPathComponent.contains("_epochs") {
            selectedFileName = "\(url.lastPathComponent) (bundled 8h sample)"
        } else {
            selectedFileName = "\(url.lastPathComponent) (bundled raw sample)"
        }
        statusMessage = "Sample data loaded. Analysis starts automatically."
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            selectedFileURL = url
            selectedFileName = url.lastPathComponent
            analysisResult = nil
            showResults = false
            statusMessage = ""
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func runAnalysis() {
        guard let fileURL = selectedFileURL else { return }

        isAnalyzing = true
        errorMessage = nil
        statusMessage = fileURL.lastPathComponent.contains("my_EEG")
            ? "Processing EEG and predicting sleep stages..."
            : "Running on-device sleep analysis..."

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let output = try SleepAnalysisEngine().analyze(fileURL: fileURL)
                DispatchQueue.main.async {
                    isAnalyzing = false
                    analysisResult = output.result
                    sleepReportStore.save(output, sourceFileName: selectedFileName.isEmpty ? fileURL.lastPathComponent : selectedFileName)
                    showResults = true
                    statusMessage = "Analysis complete."
                }
            } catch {
                DispatchQueue.main.async {
                    isAnalyzing = false
                    errorMessage = error.localizedDescription
                    statusMessage = ""
                }
            }
        }
    }
}

#Preview {
    AnalyzeSleepView()
        .environmentObject(SleepReportStore())
}
