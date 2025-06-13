//
//  CameraView.swift
//  testingvision
//
//  Created by Regina Celine Adiwinata on 13/06/25.
//

import SwiftUI
import AVFoundation
import Vision
import CoreML
import UIKit

// MARK: - Main App View
struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var predictions: [(String, Double)] = []
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var pictureCount = 0
    @State private var showResults = false
    @State private var finalResults: [(String, Double, Int)] = []
    
    private let totalPictures = 6
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreview(cameraManager: cameraManager)
                .ignoresSafeArea()
            
            VStack {
                // Picture Counter (Top Right)
                HStack {
                    Spacer()
                    VStack {
                        Text("\(pictureCount)/\(totalPictures)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(20)
                        
                        if pictureCount < totalPictures && pictureCount > 0 {
                            Text("Keep going!")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.7))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 50)
                }
                
                Spacer()
                
                // Instructions or Results
                VStack(spacing: 15) {
                    if showResults {
                        // Final Results Display
                        VStack(spacing: 10) {
                            Text("Your Face Shape Results")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.bottom, 5)
                            
                            ForEach(Array(finalResults.enumerated()), id: \.offset) { index, result in
                                HStack {
                                    Text("\(index + 1).")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text(result.0.capitalized)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("\(Int(result.1))%")
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                        Text("(\(result.2) votes)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(10)
                            }
                            
                            // Reset Button
                            Button("Take New Photos") {
                                resetSession()
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                            .padding(.top, 10)
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(15)
                    } else {
                        // Instructions
                        VStack(spacing: 8) {
                            if pictureCount == 0 {
                                Text("Take 6 photos from different angles")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Try: front, slight left, slight right, slight up, slight down, neutral")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            } else if pictureCount < totalPictures {
                                Text("Picture \(pictureCount + 1) of \(totalPictures)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Try a different angle or expression")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(15)
                    }
                    
                    // Capture Button (only show if not showing results)
                    if !showResults {
                        Button(action: capturePhoto) {
                            ZStack {
                                Circle()
                                    .fill(pictureCount >= totalPictures ? Color.green : Color.white)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 90, height: 90)
                                
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: pictureCount >= totalPictures ? .white : .black))
                                } else if pictureCount >= totalPictures {
                                    Image(systemName: "checkmark")
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(isProcessing)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .onAppear {
            cameraManager.requestPermission()
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func capturePhoto() {
        if pictureCount >= totalPictures {
            // Calculate final results
            calculateFinalResults()
            return
        }
        
        isProcessing = true
        cameraManager.capturePhoto { image in
            guard let image = image else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.alertMessage = "Failed to capture photo"
                    self.showAlert = true
                }
                return
            }
            
            // Process the captured image
            FaceShapePredictor.shared.predictFaceShape(from: image) { result in
                DispatchQueue.main.async {
                    self.isProcessing = false
                    
                    switch result {
                    case .success(let (predictedShape, confidence)):
                        self.predictions.append((predictedShape, confidence))
                        self.pictureCount += 1
                        
                        // Show results after 6 pictures
                        if self.pictureCount >= self.totalPictures {
                            self.calculateFinalResults()
                        }
                        
                    case .failure(let error):
                        self.alertMessage = error.localizedDescription
                        self.showAlert = true
                    }
                }
            }
        }
    }
    
    private func calculateFinalResults() {
        // Group predictions by face shape and calculate stats
        var shapeStats: [String: (totalConfidence: Double, count: Int)] = [:]
        
        for (shape, confidence) in predictions {
            if let existing = shapeStats[shape] {
                shapeStats[shape] = (existing.totalConfidence + confidence, existing.count + 1)
            } else {
                shapeStats[shape] = (confidence, 1)
            }
        }
        
        // Calculate average confidence and sort by count, then by average confidence
        let sortedResults = shapeStats.map { (shape, stats) in
            let avgConfidence = stats.totalConfidence / Double(stats.count)
            return (shape, avgConfidence, stats.count)
        }.sorted { first, second in
            if first.2 != second.2 {
                return first.2 > second.2  // Sort by count first
            }
            return first.1 > second.1  // Then by average confidence
        }
        
        // Take top 3 results
        finalResults = Array(sortedResults.prefix(3))
        showResults = true
    }
    
    private func resetSession() {
        predictions = []
        pictureCount = 0
        showResults = false
        finalResults = []
    }
}
