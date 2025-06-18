//
//  RecommendationView.swift
//  testingvision
//
//  Created by Regina Celine Adiwinata on 13/06/25.
//


import SwiftUI

// Define a custom color to match the UI's accent color
extension Color {
    static let accentRed = Color(red: 203/255, green: 124/255, blue: 129/255)
}

struct RecommendationView: View {
    // This action can be provided by the parent view to handle dismissal
    var dismissAction: () -> Void = {}
    
    var image: UIImage?
    // The unused 'result' parameter has been removed for clarity.
    // 'finalResults' is used for face shape, 'result2' is for skin tone.
    var result2: [String: Double]?
    let finalResults: [(String, Double, Int)]

    var body: some View {
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
            if let image = image {
                Image(uiImage: image)
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
