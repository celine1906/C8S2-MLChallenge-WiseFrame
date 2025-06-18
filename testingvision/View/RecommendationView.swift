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
    var result2 : String?
    let finalResults: [(String, Double, Int)]

    var body: some View {
        VStack {
            NavigationLink(destination: GlassesARContainerView()) {
                                Text("Mulai AR Kacamata")
                                    .padding()
                                    .foregroundColor(.white)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
//                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            
            Text("Result from 3 labels model: \(result ?? "Gagal Deteksi")")
                .font(.headline)
            Text("Result from 4 labels model: \(result2 ?? "Gagal Deteksi")")
                .font(.headline)

//            Text("Brightness: \(String(format: "%.2f", brightness))")
//                .font(.headline)
//
//            if isTooYellow {
//                Text("⚠️ Lighting too yellow!")
//                    .foregroundColor(.yellow)
//                    .bold()
//            } else {
//                Text("✅ Lighting is fine.")
//                    .foregroundColor(.green)
//            }

            Spacer()
            
            VStack(spacing: 10) {
                Text("Your Face Shape Results")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 5)
                
                ForEach(Array(finalResults.enumerated()), id: \.offset) { index, result in
                    HStack {
                        Text("\(index + 1).")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(result.0.capitalized)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(Int(result.1))%")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text("(\(result.2) votes)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                }
                
            }
            .padding()
            .background(Color.black.opacity(0.5))
            .cornerRadius(15)
        }
        .padding()
        .navigationBarHidden(true)
        .navigationTitle("Result")
    }
}

