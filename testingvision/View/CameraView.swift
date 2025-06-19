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
    let result3Labels: [String: Double]?
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
    @State private var allLandmarks: [[CGPoint]] = []
    @State private var showResults = false
    @State private var finalResults: [(String, Double, Int)] = []
    @StateObject private var mlModel = SkinToneClassification()
    @State private var resultData: ResultData?
    @State private var isShowingResult = false
    
    // FIXED: Store all predictions from 6 photos
    @State private var allFaceShapePredictions: [[(String, Double)]] = []
    
    private let totalPictures = 6
    
    private var instructionText: String {
        switch pictureCount {
            case 0:
                return "Front View"
            case 1:
                return "Slight Left"
            case 2:
                return "Slight Right"
            case 3:
                return "Slight Up"
            case 4:
                return "Slight Down"
            case 5:
                return "Smile"
            default:
                return "Complete"
            }
        }
    
    private var instructionSubtext: String {
        switch pictureCount {
        case 0:
            return "center the camera directly in front of your face"
        case 1:
            return "turn your head slightly to the left"
        case 2:
            return "turn your head slightly to the right"
        case 3:
            return "tilt your head slightly up"
        case 4:
            return "tilt your head slightly down"
        case 5:
            return "look straight at the camera and smile!"
        default:
            return "analysis complete"
        }
    }
    
    var body: some View {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Spacer()
                        
                        Text("Face Scan")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Dismiss()
                        
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Camera Card
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Camera Preview with corner brackets
                        ZStack {
                            CameraPreview(cameraManager: cameraManager)
                                .clipShape(RoundedRectangle(cornerRadius: 17))
                                .frame(height: 500)
                            
                            // Instruction Box - now placed BELOW the camera preview
                            VStack(spacing: 8) {
                                Text(instructionText)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text(instructionSubtext)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.pinkMain.opacity(0.5))
                            .cornerRadius(12)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .padding(.top, 30)
                            .padding(.horizontal, 28)
                            
                            VStack {
                                HStack {
                                    Image("topLeft")
                                    Spacer()
                                    Image("topRight")
                                }
                                Spacer()
                                HStack {
                                    Image("bottomLeft")
                                    
                                    Spacer()
                                    
                                    // Picture counter
                                    Text("\(pictureCount)/\(totalPictures)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.pinkMain.opacity(0.5))
                                        .cornerRadius(16)
                                    
                                    Spacer()
                                    
                                    Image("bottomRight")
                                }
                            }
                            .padding(16)
                        }
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        

                    }
                    .frame(maxWidth: 350)
                    .padding(.horizontal, 20)

                    
                    Spacer()
                    
                    // Capture Button
                    if pictureCount < totalPictures {
                        Button(action: capturePhoto) {
                            HStack {
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "camera.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                }
                                
                                Text(isProcessing ? "Processing..." : "CAPTURE")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                Color(red: 0.73, green: 0.4, blue: 0.39)
                            )
                            .cornerRadius(16)
                            .shadow(color: Color(red: 0.73, green: 0.4, blue: 0.39).opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isProcessing)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .onAppear {
                cameraManager.requestPermission()
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $isShowingResult) {
                if let result = resultData {
                    RecommendationView(
                        image: result.faceImage,
//                        result: result.result3Labels,
                        result2: result.result4Labels,
                        finalResults: finalResults
                    )
                } else {
                    EmptyView()
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK") {
                    isProcessing = false
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
            
            // Handle skin tone classification for the first photo only
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
                      let prediction2 = mlModel.classifySkinTone(image: croppedImage) else {
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        self.alertMessage = "Failed to analyze skin tone"
                        self.showAlert = true
                    }
                    return
                }
                
                self.resultData = ResultData(
                    faceImage: croppedImage,
                    result3Labels: prediction,
                    result4Labels: prediction2
                )
            }
            
            // Start face shape prediction and landmarks extraction
            print("🔄 Starting face shape prediction for photo \(pictureCount + 1)")
            
            // Extract face landmarks for this photo
            FaceShapePredictor.shared.extractLandmarks(from: image) { landmarks in
                if let landmarks = landmarks {
                    // Store landmarks for this photo
                    self.allLandmarks.append(landmarks)
                    
                    // Proceed with face shape prediction
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
                                
                                // Store this photo's face shape predictions
                                self.allFaceShapePredictions.append(top3)
                                
                                // Update picture count
                                self.pictureCount += 1
                                
                                // If all photos have been captured, calculate final results
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
                } else {
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        self.alertMessage = "Failed to detect face landmarks"
                        self.showAlert = true
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
