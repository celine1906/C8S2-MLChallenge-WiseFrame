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
//     var result: String?
    // This action can be provided by the parent view to handle dismissal
    var dismissAction: () -> Void = {}
    
    var image: UIImage?
    // The unused 'result' parameter has been removed for clarity.
    // 'finalResults' is used for face shape, 'result2' is for skin tone.
    var result2: [String: Double]?
    let finalResults: [(String, Double, Int)]
    
    @State private var processedImage: UIImage?
    
    var body: some View {
//         VStack {
//             Text("Your Result")
//                 .font(.title)
//                 .fontWeight(.medium)
//                 .padding(.top)
            
//             if let displayImage = processedImage ?? image {
//                 Image(uiImage: displayImage)
//                     .resizable()
//                     .scaledToFit()
//                     .frame(height: 200)
//                     .clipShape(RoundedRectangle(cornerRadius: 15))
//                     .background(Color.white)
//             }
            
//             Text("Based on your pictures")
//                 .font(.headline)
//                 .foregroundColor(.black)
//                 .padding(.top, 10)
            
//             VStack {
//                 Text("Face Shape Results")
//                     .font(.title2)
//                     .fontWeight(.bold)
//                     .foregroundColor(.black)
//                     .padding(.bottom, 5)
                
//                 ForEach(Array(finalResults.enumerated()), id: \.offset) { index, result in
//                     HStack {
//                         Text("\(index + 1).")
//                             .font(.headline)
//                             .foregroundColor(.black)
                        
//                         Text(result.0.capitalized)
//                             .font(.headline)
//                             .fontWeight(.semibold)
//                             .foregroundColor(.black)
                        
//                         ProgressView(value: result.1 / 100.0)
//                             .progressViewStyle(LinearProgressViewStyle(tint: Color.gray))
//                             .frame(height: 10)
                        
//                         Text("\(Int(result.1))%")
//                             .font(.subheadline)
//                             .foregroundColor(.black)
//                     }
//                     .padding(.horizontal, 16)
//                     .padding(.vertical, 8)
//                 }
//             }
//             .padding()
//             .background(
//                 RoundedRectangle(cornerRadius: 15)
//                     .fill(Color.white)
//             )
//             .overlay(
//                 RoundedRectangle(cornerRadius: 15)
//                     .stroke(Color.gray.opacity(0.3), lineWidth: 2)
//             )
            
//             VStack {
//                 Text("Skin Tone Results")
//                     .font(.title2)
//                     .fontWeight(.bold)
//                     .foregroundColor(.black)
//                     .padding(.bottom, 5)
                
//                 if let skinToneResults = result2 {
//                     let topTwoResults = skinToneResults.sorted(by: { $0.value > $1.value }).prefix(2)
                    
//                     ForEach(Array(topTwoResults.enumerated()), id: \.offset) { index, result in
//                         HStack {
//                             Text("\(index + 1).")
//                                 .font(.headline)
//                                 .foregroundColor(.black)
                            
//                             Text(result.0.capitalized)
//                                 .font(.headline)
//                                 .fontWeight(.semibold)
//                                 .foregroundColor(.black)
                            
//                             ProgressView(value: result.1)
//                                 .progressViewStyle(LinearProgressViewStyle(tint: Color.gray))
//                                 .frame(height: 10)
                            
//                             Text("\(Int(result.1 * 100))%")
//                                 .font(.subheadline)
//                                 .foregroundColor(.black)
//                         }
//                         .padding(.horizontal, 16)
//                         .padding(.vertical, 8)
//                     }
//                 }
//             }
//             .padding()
//             .background(
//                 RoundedRectangle(cornerRadius: 15)
//                     .fill(Color.white)
//             )
//             .overlay(
//                 RoundedRectangle(cornerRadius: 15)
//                     .stroke(Color.gray.opacity(0.3), lineWidth: 2)
//             )
            
//             // "Try-on Glasses" Button
//             NavigationLink(destination: GlassesTryOnView()) {
//                 Text("Try-on Glasses")
//                     .padding()
//                     .foregroundColor(.white)
//                     .background(Color.black)
//                     .cornerRadius(10)
//             }
//         }
//         .padding()
//         .navigationBarHidden(true)
//         .navigationTitle("Result")
//         .onAppear {
//             if let image = image {
//                 processImageWithLandmarks(image: image)
//             }
//         }
      VStack(spacing: 24) {
            // MARK: - Header
            HStack {
                Text("Your Result")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    // Action to dismiss the view would go here
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
                if let topFaceShape = finalResults.max(by: { $0.1 < $1.1 }) {
                    ResultBox(
                        title: "Your face shape is most likely",
                        result: topFaceShape.0.capitalized
                    )
                }

                // Skin Tone Box
                if let skinToneResults = result2,
                   let topSkinTone = skinToneResults.max(by: { $0.value < $1.value }) {
                    ResultBox(
                        title: "Your skin tone is most likely",
                        result: topSkinTone.key.capitalized
                    )
                }
            }
            .padding(.horizontal)
                        

            // MARK: - Recommendation Button
            // The destination view 'GlassesTryOnView' is assumed to exist.
            // If it doesn't, this can be changed to a standard Button.
            NavigationLink(destination:  GlassesTryOnView()) {
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


// Preview
struct RecommendationView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample image for preview
        let sampleImage = UIImage(named: "preview_person_face") ?? UIImage(systemName: "person.fill")!
        
        // Sample face shape results
        let faceShapeResults: [(String, Double, Int)] = [
            ("Oval", 85.0, 1),
            ("Round", 10.0, 0),
            ("Square", 5.0, 0)
        ]
        
        // Sample skin tone results (updated to match UI)
        let skinToneResults: [String: Double] = [
            "Light": 0.9,
            "Cool": 0.1
        ]
        
        // Embed in NavigationView for the NavigationLink to function in preview
        NavigationView {
            RecommendationView(
                image: sampleImage,
                result2: skinToneResults,
                finalResults: faceShapeResults
            )
        }
    }
}
