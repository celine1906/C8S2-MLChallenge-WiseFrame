//
//  RecommendationView.swift
//  testingvision
//
//  Created by Regina Celine Adiwinata on 13/06/25.
//


import SwiftUI

struct RecommendationView: View {
    var image: UIImage?
//    var brightness: Float
//    var isTooYellow: Bool
    var result: String?
    var result2 : [String: Double]?
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
            
            VStack() {
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
                        
                        ProgressView(value: 0.25)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color.red))
                            .frame(height: 10)
                        
//                        VStack(alignment: .trailing) {
                            Text("\(Int(result.1))%")
                                .font(.subheadline)
                                .foregroundColor(.black)
//                            Text("(\(result.2) votes)")
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
//                    .background(Color.black.opacity(0.6))
//                    .cornerRadius(10)
                }
                
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.pinkMain, lineWidth: 5)
            )
            
            VStack() {
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
                                .progressViewStyle(LinearProgressViewStyle(tint: Color.red))
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
                    .stroke(Color.pinkMain, lineWidth: 5)
            )
            

            
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

