//
//  RecommendationView.swift
//  testingvision
//
//  Created by Regina Celine Adiwinata on 13/06/25.
//


import SwiftUI

struct RecommendationView: View {
    var image: UIImage?
    var result: String?
    var result2: [String: Double]?
    let finalResults: [(String, Double, Int)]

    var body: some View {
        VStack {
            Text("Your Result")
                .font(.title)
                .fontWeight(.medium)
                .padding(.top)

            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay(RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.red.opacity(0.5), lineWidth: 3))
            }

            Text("Based on your pictures")
                .font(.headline)
                .foregroundColor(.red)
                .padding(.top, 10)

            // Face Shape Section (Top One Only)
            if let topFaceShape = finalResults.max(by: { $0.1 < $1.1 }) {
                VStack {
                    Text("Face Shape Result")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.bottom, 5)

                    HStack {
                        Text("1.")
                            .font(.headline)
                            .foregroundColor(.black)

                        Text(topFaceShape.0.capitalized)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)

                        ProgressView(value: topFaceShape.1 / 100.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color.red))
                            .frame(height: 10)

                        Text("\(Int(topFaceShape.1))%")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 15).fill(Color.white))
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.pinkMain, lineWidth: 5))
            }

            // Skin Tone Section (Top One Only)
            if let skinToneResults = result2,
               let topSkinTone = skinToneResults.max(by: { $0.value < $1.value }) {
                VStack {
                    Text("Skin Tone Result")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.bottom, 5)

                    HStack {
                        Text("1.")
                            .font(.headline)
                            .foregroundColor(.black)

                        Text(topSkinTone.key.capitalized)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)

                        ProgressView(value: topSkinTone.value)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color.red))
                            .frame(height: 10)

                        Text("\(Int(topSkinTone.value * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 15).fill(Color.white))
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.pinkMain, lineWidth: 5))
            }

            NavigationLink(destination: GlassesTryOnView()) {
                Text("Try-on Glasses")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.pinkMain)
                    .cornerRadius(10)
            }
        }
        .padding()
        .navigationBarHidden(true)
        .navigationTitle("Result")
    }
}


// Preview
struct RecommendationView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample image for preview (using system image for simulation)
        let sampleImage = UIImage(systemName: "person.fill") // Replace with actual test image if available
        
        // Sample face shape results
        let faceShapeResults: [(String, Double, Int)] = [
            ("oval", 75.0, 120),
            ("round", 15.0, 24),
            ("square", 10.0, 12)
        ]
        
        // Sample skin tone results
        let skinToneResults: [String: Double] = [
            "warm": 0.65,
            "cool": 0.35
        ]
        
        return RecommendationView(
            image: sampleImage,
            result: "oval",
            result2: skinToneResults,
            finalResults: faceShapeResults
        )
    }
}

