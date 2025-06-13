//
//  FaceShapePredictor.swift
//  testingvision
//
//  Created by Regina Celine Adiwinata on 13/06/25.
//

import UIKit
import Vision

// MARK: - Face Shape Predictor
class FaceShapePredictor {
    static let shared = FaceShapePredictor()
    private var model: MLModel?
    
    private init() {
        loadModel()
    }
    
    private func loadModel() {
        print("\(#function)")
        guard let model = try? randomforest(configuration: MLModelConfiguration()) else {
            print("Failed to load ML model")
            return
        }
        
        self.model = model.model
    }
    
    func predictFaceShape(from image: UIImage, completion: @escaping (Result<(String, Double), Error>) -> Void) {
        print("\(#function)")
        guard let model = model else {
            completion(.failure(PredictionError.modelNotLoaded))
            return
        }
        
        // Extract landmarks from the image
        extractLandmarks(from: image) { landmarks in
            guard let landmarks = landmarks else {
                completion(.failure(PredictionError.landmarkExtractionFailed))
                return
            }
            
            // Create feature array for prediction
            guard let features = self.createFeatureArray(from: landmarks) else {
                completion(.failure(PredictionError.featureCreationFailed))
                return
            }
            
            // Make prediction
            do {
                let prediction = try model.prediction(from: features)
                
                // Extract prediction result
                if let classLabelOutput = prediction.featureValue(for: "label")?.stringValue,
                   let classProbability = prediction.featureValue(for: "labelProbability")?.dictionaryValue {
                    
                    let confidence = classProbability[classLabelOutput]?.doubleValue ?? 0.0
                    completion(.success((classLabelOutput, confidence * 100))) // Convert to percentage
                } else {
                    completion(.failure(PredictionError.predictionFailed))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func extractLandmarks(from image: UIImage, completion: @escaping ([CGPoint]?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let request = VNDetectFaceLandmarksRequest { request, error in
            guard let results = request.results as? [VNFaceObservation],
                  let face = results.first,
                  let landmarks = face.landmarks else {
                completion(nil)
                return
            }
            
            let processedLandmarks = self.processFaceLandmarks(landmarks)
            completion(processedLandmarks)
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Error performing landmark detection: \(error)")
                completion(nil)
            }
        }
    }
    
    private func processFaceLandmarks(_ landmarks: VNFaceLandmarks2D) -> [CGPoint] {
        var coordinates: [CGPoint] = []
        
        // Add landmarks in the same order as your training data
        if let faceContour = landmarks.faceContour {
            coordinates.append(contentsOf: faceContour.normalizedPoints)
        }
        if let leftEyebrow = landmarks.leftEyebrow {
            coordinates.append(contentsOf: leftEyebrow.normalizedPoints)
        }
        if let rightEyebrow = landmarks.rightEyebrow {
            coordinates.append(contentsOf: rightEyebrow.normalizedPoints)
        }
        if let nose = landmarks.nose {
            coordinates.append(contentsOf: nose.normalizedPoints)
        }
        if let noseCrest = landmarks.noseCrest {
            coordinates.append(contentsOf: noseCrest.normalizedPoints)
        }
        if let leftEye = landmarks.leftEye {
            coordinates.append(contentsOf: leftEye.normalizedPoints)
        }
        if let rightEye = landmarks.rightEye {
            coordinates.append(contentsOf: rightEye.normalizedPoints)
        }
        if let outerLips = landmarks.outerLips {
            coordinates.append(contentsOf: outerLips.normalizedPoints)
        }
        if let innerLips = landmarks.innerLips {
            coordinates.append(contentsOf: innerLips.normalizedPoints)
        }
        if let leftPupil = landmarks.leftPupil {
            coordinates.append(contentsOf: leftPupil.normalizedPoints)
        }
        if let rightPupil = landmarks.rightPupil {
            coordinates.append(contentsOf: rightPupil.normalizedPoints)
        }
        if let medianLine = landmarks.medianLine {
            coordinates.append(contentsOf: medianLine.normalizedPoints)
        }
        
        // Ensure exactly 68 points
        while coordinates.count < 68 {
            coordinates.append(CGPoint(x: 0, y: 0))
        }
        if coordinates.count > 68 {
            coordinates = Array(coordinates.prefix(68))
        }
        
        return coordinates
    }
    
    private func createFeatureArray(from landmarks: [CGPoint]) -> MLFeatureProvider? {
        var featureDict: [String: Any] = [:]
        
        // Create feature dictionary with the same format as training data
        for (index, point) in landmarks.enumerated() {
            featureDict["landmark_\(index)_x"] = point.x
            featureDict["landmark_\(index)_y"] = point.y
        }
        
        do {
            return try MLDictionaryFeatureProvider(dictionary: featureDict)
        } catch {
            print("Error creating feature provider: \(error)")
            return nil
        }
    }
}

// MARK: - Prediction Errors
enum PredictionError: LocalizedError {
    case modelNotLoaded
    case landmarkExtractionFailed
    case featureCreationFailed
    case predictionFailed
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "ML model could not be loaded"
        case .landmarkExtractionFailed:
            return "Could not detect face landmarks"
        case .featureCreationFailed:
            return "Could not create features for prediction"
        case .predictionFailed:
            return "Prediction failed"
        }
    }
}
