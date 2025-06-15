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
    let result4Labels: String?
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
//                    if showResults {
//                        // Final Results Display
//  
//                    } else {
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
//                    }
                    
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
            Button("OK") { }
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
            
            if pictureCount == 0 {
                guard let croppedImage = self.cropImage(image) else { return }
                guard let prediction = mlModel.classifySkinTone(image: croppedImage) else { return }
                guard let prediction2 = mlModel.classifySkinTone2(image: croppedImage) else { return }
                self.resultData = ResultData(
                    faceImage: croppedImage,
                    result3Labels: prediction,
                    result4Labels: prediction2
                )
            }
            
            FaceShapePredictor.shared.predictFaceShape(from: image) { result in
                DispatchQueue.main.async {
                    self.isProcessing = false
                    
                    switch result {
                    case .success(let (predictedShape, confidence)):
                        self.predictions.append((predictedShape, confidence))
                        self.pictureCount += 1
                        
                        if self.pictureCount >= self.totalPictures {
                            Task {
                                await self.calculateFinalResults()
                                DispatchQueue.main.async {
                                    self.isShowingResult = true
                                }
                            }
                        }
                        
                    case .failure(let error):
                        self.alertMessage = error.localizedDescription
                        self.showAlert = true
                    }
                }
            }
        }
    }

    
    private func calculateFinalResults() async {
        var shapeStats: [String: (totalConfidence: Double, count: Int)] = [:]
        
        for (shape, confidence) in predictions {
            if let existing = shapeStats[shape] {
                shapeStats[shape] = (existing.totalConfidence + confidence, existing.count + 1)
            } else {
                shapeStats[shape] = (confidence, 1)
            }
        }
        
        let sortedResults = shapeStats.map { (shape, stats) in
            let avgConfidence = stats.totalConfidence / Double(stats.count)
            return (shape, avgConfidence, stats.count)
        }.sorted { first, second in
            if first.2 != second.2 {
                return first.2 > second.2
            }
            return first.1 > second.1
        }

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
