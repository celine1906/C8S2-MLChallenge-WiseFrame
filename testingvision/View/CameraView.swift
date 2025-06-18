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

struct ResultData: Hashable {
    let faceImage: UIImage?
//    let brightness: Float
//    let isTooYellow: Bool
    let result3Labels: String?
    let result4Labels: [String: Double]?
}


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
    @StateObject private var mlModel = SkinToneClassification()
    @State private var resultData: ResultData?
    @State private var isShowingResult = false
    
    // FIXED: Store all predictions from 6 photos
    @State private var allFaceShapePredictions: [[(String, Double)]] = []
    
    private let totalPictures = 6
    
    var body: some View {
        ZStack() {
            Color.white
            VStack {
                Dismiss()

                Spacer()
            }
            
            ZStack {
                // Camera Preview
                CameraPreview(cameraManager: cameraManager)
                    
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
                        Text("Picture \(pictureCount) of \(totalPictures)")
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
                    .foregroundColor(Color(red: 0.73, green: 0.4, blue: 0.39, opacity: 0.5))
                    .padding(.trailing, 8)
                    .padding(.top, 10)
                }
                
            }
//            .frame(maxWidth:334, maxHeight: 500)
            
            
            
            
            VStack {
                // Picture Counter (Top Right)
                
                
                Spacer()
                
                // Instructions or Results
                VStack(spacing: 15) {
//                    if showResults {
//                        // Final Results Display
//  
//                    } else {
                        // Instructions
              
//                    }
                    
                    // Capture Button
                    if pictureCount < totalPictures {
                        Button(action: capturePhoto) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 90, height: 90)
                                
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Image(systemName: "camera")
                                        .font(.title)
                                        .foregroundColor(.black)
                                }
                            }
                        }
                        .disabled(isProcessing)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
        .padding()
        .onAppear {
            cameraManager.requestPermission()
        }
//        .navigationTitle("Scan Face")
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $isShowingResult) {
            if let result = resultData {
                RecommendationView(
                    image: result.faceImage,
//                    brightness: result.brightness,
//                    isTooYellow: result.isTooYellow,
                    result: result.result3Labels,
                    result2: result.result4Labels,
                    finalResults: finalResults
                )
            } else {
                EmptyView()
            }
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK") {
                isProcessing = false // Reset processing state on error
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func cropImage(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNDetectFaceRectanglesRequest()
        
        do {
            try handler.perform([request])
            guard let results = request.results, let face = results.first else {
                return nil
            }
            
            let boundingBox = face.boundingBox
            let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
            let rect = CGRect(
                x: boundingBox.origin.x * imageSize.width,
                y: (1 - boundingBox.origin.y - boundingBox.size.height) * imageSize.height,
                width: boundingBox.size.width * imageSize.width,
                height: boundingBox.size.height * imageSize.height
            )
            
            if let croppedCGImage = cgImage.cropping(to: rect) {
                return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation).normalizedImage()
            } else {
                return nil
            }
        } catch {
            print("Face detection failed: \(error)")
            return nil
        }
    }

    
    private func capturePhoto() {
        guard pictureCount < totalPictures else { return }

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
            
            // FIXED: Handle skin tone classification for first photo only
            if pictureCount == 0 {
                guard let croppedImage = self.cropImage(image) else {
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        self.alertMessage = "Failed to detect face for skin tone analysis"
                        self.showAlert = true
                    }
                    return
                }
                
                guard let prediction = mlModel.classifySkinTone(image: croppedImage),
                      let prediction2 = mlModel.classifySkinTone2(image: croppedImage) else {
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        self.alertMessage = "Failed to analyze skin tone"
                        self.showAlert = true
                    }
                    return
                }
                
                self.resultData = ResultData(
                    faceImage: image,
                    result3Labels: prediction,
                    result4Labels: prediction2
                )
            }
            
            // FIXED: Properly handle face shape prediction with completion
            print("🔄 Starting face shape prediction for photo \(pictureCount + 1)")
            
            FaceShapePredictor.shared.predictFaceShape(from: image) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let (primaryPrediction, primaryConfidence, top3)):
                        print("🎯 Photo \(self.pictureCount + 1) - Primary: \(primaryPrediction) (\(String(format: "%.1f", primaryConfidence))%)")
                        print("🏆 Top 3:")
                        for (index, (className, confidence)) in top3.enumerated() {
                            let rank = index == 0 ? "🥇" : (index == 1 ? "🥈" : "🥉")
                            print("   \(rank) \(className): \(String(format: "%.1f", confidence))%")
                        }
                        
                        // Store this photo's prediction
                        self.allFaceShapePredictions.append(top3)
                        
                        // Update picture count
                        self.pictureCount += 1
                        
                        // If we've captured all photos, calculate final results
                        if self.pictureCount >= self.totalPictures {
                            Task {
                                await self.calculateFinalResults()
                            }
                        }
                        
                        // Reset processing state
                        self.isProcessing = false
                        
                    case .failure(let error):
                        print("❌ Face shape prediction error: \(error)")
                        self.alertMessage = "Failed to analyze face shape: \(error.localizedDescription)"
                        self.showAlert = true
                        self.isProcessing = false
                    }
                }
            }
        }
    }

    
    private func calculateFinalResults() async {
        print("📊 Calculating final results from \(allFaceShapePredictions.count) photos...")
        
        // Aggregate all predictions across all photos
        var shapeStats: [String: (totalConfidence: Double, count: Int)] = [:]
        
        // Process each photo's top 3 predictions
        for photoIndex in 0..<allFaceShapePredictions.count {
            let photoPredictions = allFaceShapePredictions[photoIndex]
            print("📸 Photo \(photoIndex + 1) predictions:")
            
            for (shape, confidence) in photoPredictions {
                print("   \(shape): \(String(format: "%.1f", confidence))%")
                
                if let existing = shapeStats[shape] {
                    shapeStats[shape] = (existing.totalConfidence + confidence, existing.count + 1)
                } else {
                    shapeStats[shape] = (confidence, 1)
                }
            }
        }
        
        // Calculate average confidence for each shape
        let sortedResults = shapeStats.map { (shape, stats) in
            let avgConfidence = stats.totalConfidence / Double(stats.count)
            return (shape, avgConfidence, stats.count)
        }.sorted { first, second in
            // Sort by count first (more frequent predictions), then by confidence
            if first.2 != second.2 {
                return first.2 > second.2
            }
            return first.1 > second.1
        }

        finalResults = Array(sortedResults.prefix(3))
        
        print("🎯 FINAL AGGREGATED RESULTS:")
        for (index, (shape, avgConfidence, count)) in finalResults.enumerated() {
            let rank = index == 0 ? "🥇" : (index == 1 ? "🥈" : "🥉")
            print("   \(rank) \(shape): \(String(format: "%.1f", avgConfidence))% avg (appeared \(count) times)")
        }
        
        isShowingResult.toggle()
        
        showResults = true
    }
    
    private func resetSession() {
        predictions = []
        pictureCount = 0
        showResults = false
        finalResults = []
        allFaceShapePredictions = []
        resultData = nil
        isProcessing = false
    }
}

extension UIImage {
    func normalizedImage() -> UIImage {
        if imageOrientation == .up {
            return self
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? self
    }
}
