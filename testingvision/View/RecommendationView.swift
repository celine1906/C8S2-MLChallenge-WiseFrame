//
//  RecommendationView.swift
//  testingvision
//
//  Created by Regina Celine Adiwinata on 13/06/25.
//

import SwiftUI
import Vision

struct RecommendationView: View {
    @StateObject var faceShapePredictor = FaceShapePredictor()
    var image: UIImage?
    var result: String?
    var result2: [String: Double]?
    let finalResults: [(String, Double, Int)]
    
    @State private var processedImage: UIImage?
    
    var body: some View {
        VStack {
            Text("Your Result")
                .font(.title)
                .fontWeight(.medium)
                .padding(.top)
            
            if let displayImage = processedImage ?? image {
                Image(uiImage: displayImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .background(Color.white)
            }
            
            Text("Based on your pictures")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.top, 10)
            
            VStack {
                Text("Face Shape Results")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.bottom, 5)
                
                ForEach(Array(finalResults.enumerated()), id: \.offset) { index, result in
                    HStack {
                        Text("\(index + 1).")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Text(result.0.capitalized)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        
                        ProgressView(value: result.1 / 100.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color.gray))
                            .frame(height: 10)
                        
                        Text("\(Int(result.1))%")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            )
            
            VStack {
                Text("Skin Tone Results")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.bottom, 5)
                
                if let skinToneResults = result2 {
                    let topTwoResults = skinToneResults.sorted(by: { $0.value > $1.value }).prefix(2)
                    
                    ForEach(Array(topTwoResults.enumerated()), id: \.offset) { index, result in
                        HStack {
                            Text("\(index + 1).")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            Text(result.0.capitalized)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                            
                            ProgressView(value: result.1)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color.gray))
                                .frame(height: 10)
                            
                            Text("\(Int(result.1 * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            )
            
            // "Try-on Glasses" Button
            NavigationLink(destination: GlassesTryOnView()) {
                Text("Try-on Glasses")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.black)
                    .cornerRadius(10)
            }
        }
        .padding()
        .navigationBarHidden(true)
        .navigationTitle("Result")
        .onAppear {
            if let image = image {
                processImageWithLandmarks(image: image)
            }
        }
    }
    
    private func processImageWithLandmarks(image: UIImage) {
        guard let cgImage = image.cgImage else {
            print("Failed to get CGImage")
            return
        }
        
        let request = VNDetectFaceLandmarksRequest { request, error in
            if let error = error {
                print("Vision error: \(error)")
                return
            }
            
            guard let observations = request.results as? [VNFaceObservation] else {
                print("No face observations found")
                self.processedImage = image
                return
            }
            
            print("Found \(observations.count) face(s)")
            
            DispatchQueue.main.async {
                self.drawLandmarksOnImage(image: image, observations: observations)
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform landmark detection: \(error)")
            self.processedImage = image
        }
    }
    
    private func drawLandmarksOnImage(image: UIImage, observations: [VNFaceObservation]) {
        guard let observation = observations.first,
              let landmarks = observation.landmarks else {
            print("No landmarks found")
            self.processedImage = image
            return
        }
        
        // Create a graphics context
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        
        // Draw the original image
        image.draw(at: CGPoint.zero)
        
        // Get the current graphics context
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            self.processedImage = image
            return
        }
        
        // Set up drawing properties
        context.setFillColor(UIColor.white.cgColor)
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(3.0)
        
        // Get image dimensions
        let imageSize = image.size
        
        // Process different landmark regions
        let landmarkGroups: [VNFaceLandmarkRegion2D?] = [
            landmarks.faceContour,
            landmarks.leftEye,
            landmarks.rightEye,
            landmarks.leftEyebrow,
            landmarks.rightEyebrow,
            landmarks.nose,
            landmarks.noseCrest,
            landmarks.outerLips,
            landmarks.innerLips
        ]
        
        for landmarkGroup in landmarkGroups {
            if let group = landmarkGroup {
                for i in 0..<group.pointCount {
                    let normalizedPoint = group.normalizedPoints[i]
                    
                    // Convert Vision coordinates to image coordinates properly
                    // Vision: (0,0) is bottom-left, landmarks are relative to face bounding box
                    // Core Graphics: (0,0) is top-left
                    
                    // First convert landmark point to face-relative coordinates
                    let faceRelativeX = normalizedPoint.x
                    let faceRelativeY = normalizedPoint.y
                    
                    // Then convert to full image coordinates
                    let faceBounds = observation.boundingBox
                    let imageX = (faceBounds.origin.x + faceRelativeX * faceBounds.width) * imageSize.width
                    let imageY = (1.0 - (faceBounds.origin.y + faceRelativeY * faceBounds.height)) * imageSize.height
                    
                    // Draw a big visible circle for each landmark
                    let landmarkSize: CGFloat = 12
                    let landmarkRect = CGRect(x: imageX - landmarkSize/2, y: imageY - landmarkSize/2, width: landmarkSize, height: landmarkSize)
                    context.fillEllipse(in: landmarkRect)
                    context.strokeEllipse(in: landmarkRect)
                }
            }
        }
        
        // Get the modified image
        let modifiedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.processedImage = modifiedImage ?? image
    }
}
