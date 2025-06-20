//
//  RecommendationView.swift
//  testingvision
//
//  Created by Regina Celine Adiwinata on 13/06/25.
//

import SwiftUI
import Vision

// Define a custom color to match the UI's accent color
extension Color {
    static let accentRed = Color(red: 203/255, green: 124/255, blue: 129/255)
}

struct RecommendationView: View {
    @StateObject var faceShapePredictor = FaceShapePredictor()
    @Binding var path: NavigationPath
//     var result: String?
    // This action can be provided by the parent view to handle dismissal
    var dismissAction: () -> Void = {}
    
    var image: UIImage?
    // The unused 'result' parameter has been removed for clarity.
    // 'finalResults' is used for face shape, 'result2' is for skin tone.
    @State private var topFaceShape: String = ""
    @State private var topSkinTone: String = ""
    @State var recommendedFrameIndexes: [Int] = []
    @State var recommendedColors: [String] = []
    var viewModel=RecommendationViewModel()
    var result2: [String: Double]?
    let finalResults: [(String, Double, Int)]    
    
    @State private var processedImage: UIImage?
    
    var body: some View {
      VStack(spacing: 24) {
            // MARK: - Header
            ZStack {
              Text("Your Result")
                  .font(.largeTitle)
                  .fontWeight(.bold)
                  .frame(maxWidth: .infinity, alignment: .center)

              HStack {
                  Spacer()
                  Button(action: {
                      dismissAction()
                  }) {
                      ZStack {
                          Circle()
                              .fill(Color.accentRed)
                              .frame(width: 32, height: 32)
                          Image(systemName: "xmark")
                              .font(.system(size: 15, weight: .bold))
                              .foregroundColor(.white)
                      }
                  }
              }
            }
            .padding(.horizontal)
            .padding(.top)


            // MARK: - Image
            if let displayImage = processedImage ?? image {
                Image(uiImage: displayImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.accentRed.opacity(0.8), lineWidth: 2)
                    )
                    .padding(.horizontal)
            }

            // MARK: - Subtitle
            Text("Based on your pictures")
                .font(.headline)
                .foregroundColor(.accentRed)
                .fontWeight(.regular)

            // MARK: - Result Boxes
            HStack(spacing: 16) {
                // Face Shape Box
                ResultBox(
                    title: "Your face shape is most likely",
                    result: topFaceShape.capitalized
                )
                ResultBox(
                    title: "Your skin tone is most likely",
                    result: topSkinTone.capitalized
                )
            }
            .padding(.horizontal)
                        

            // MARK: - Recommendation Button
            // The destination view 'GlassesTryOnView' is assumed to exist.
            // If it doesn't, this can be changed to a standard Button.
          NavigationLink(destination:  GlassesTryOnView(path: $path, recommendedFrameIndexes: recommendedFrameIndexes, recommendedColors: recommendedColors)) {
                Text("See recommended frames")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentRed)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            Spacer()
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarHidden(true) // Hides the default navigation bar
        .onAppear{
            if let image = image {
                processImageWithLandmarks(image: image)
            }
            if let topShape = finalResults.max(by: { $0.1 < $1.1 })?.0 {
                let shape = topShape.lowercased()
                topFaceShape = shape
                recommendedFrameIndexes = viewModel.getRecommendedGlasses(for: shape)
            }

            if let skinToneKey = result2?.max(by: { $0.value < $1.value })?.key {
                let tone = skinToneKey.lowercased()
                topSkinTone = tone
                recommendedColors = viewModel.getRecommendedColors(for: tone)
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

// Helper View for the result boxes to avoid code repetition
struct ResultBox: View {
    let title: String
    let result: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Text(result)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.accentRed)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(10)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentRed.opacity(0.8), lineWidth: 1)
        )
    }
}
