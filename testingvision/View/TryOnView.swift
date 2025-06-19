//
//  TryOnView.swift
//  testingvision
//
//  Created by Regina Celine Adiwinata on 18/06/25.

import SwiftUI
import ARKit
import SceneKit

struct GlassesTryOnView: View {
    @State private var selectedGlassesIndex = 0
    @State var currentGlassesModel = ""
    @State private var showingARView = true
    @Environment(\.dismiss) private var dismiss
    
    @State var recommendedFrameIndexes: [Int]
    @State var recommendedColors: [String]
    
    var recommendedFrames: [GlassesModel] {
        recommendedFrameIndexes.map { glassesOptions[$0] }
    }

    let glassesOptions = [
        GlassesModel(
            name: "Rectangle",
            description: "Adds structure to softer features. A great fit for round or oval faces.",
            modelFile: "rectangle",
            frameColors: [.black, .brown, .clear]
        ),
        GlassesModel(
            name: "Round",
            description: "Vintage-style round frames, flattering for most face shapes.",
            modelFile: "round",
            frameColors: [.black, .brown, .clear]
        ),
        GlassesModel(
            name: "Aviator",
            description: "Bold and structured. Works well with rounder face types.",
            modelFile: "aviators",
            frameColors: [.black, .brown, .clear]
        ),
        GlassesModel(
            name: "Cat Eye",
            description: "Elegant and feminine. Ideal for heart-shaped and oval faces.",
            modelFile: "cateye",
            frameColors: [.black, .brown, .clear]
        ),
        GlassesModel(
            name: "Square",
            description: "Strong angles that complement rounder or oval faces.",
            modelFile: "square",
            frameColors: [.black, .brown, .clear]
        ),
        GlassesModel(
            name: "Oval",
            description: "Balanced curves, great for square or rectangular face shapes.",
            modelFile: "oval",
            frameColors: [.black, .brown, .clear]
        ),
        GlassesModel(
            name: "Geometric",
            description: "Unique angular styles for bold and modern looks. Best for oval faces.",
            modelFile: "geometric",
            frameColors: [.black, .brown, .clear]
        )
    ]

    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .padding(10)
                        .background(Circle().fill(Color(.systemGray6)))
                }

                Spacer()

                Text("Try-on")
                    .font(.title3)
                    .bold()

                Spacer()

                Button(action: {
                    
                }) {
                    Image(systemName: "xmark")
                        .padding(10)
                        .background(Circle().fill(Color(.systemGray6)))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top)

            // AR Camera View
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(red: 0.77, green: 0.47, blue: 0.47), lineWidth: 4)
                    .background(Color.white.cornerRadius(20))
                    .frame(height: 320)
                    .padding(.horizontal, 20)

                if showingARView {
                    GlassesARViewRepresentable(selectedModel: currentGlassesModel)
                        .frame(height: 320)
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        .shadow(radius: 6)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 320)
                        .overlay(Text("AR View Loading...").foregroundColor(.gray))
                        .padding(.horizontal, 20)
                }
            }
            .padding(.top, 16)


            

            // Glasses Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(recommendedFrameIndexes.enumerated()), id: \.offset) { displayIndex, originalIndex in
                           let glasses = glassesOptions[originalIndex]
                           GlassesCard(
                               glasses: glasses,
                               isSelected: selectedGlassesIndex == displayIndex,
                               isRecommended: true, // All displayed glasses are recommended
                               recommendedColors: recommendedColors,
                               currentGlassesModel: $currentGlassesModel,
                               selectedColorIndex: 0,
                               onSelect: {
                                   selectedGlassesIndex = displayIndex
                                   currentGlassesModel = "\(glasses.modelFile)_\(recommendedColors[0]).usdz"
                               }
                           )
                        }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }


            // Page Indicator
            HStack(spacing: 8) {
                ForEach(0..<recommendedFrameIndexes.count, id: \.self) { index in
                    Circle()
                        .fill(index == selectedGlassesIndex ? Color.pink : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
                .onTapGesture {
                    
                    
                }
            }
            
            .padding(.top, 12)
            Spacer()
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .onAppear {
//            if currentGlassesModel.isEmpty, let firstIndex = recommendedFrameIndexes.first {
//                currentGlassesModel = glassesOptions[firstIndex].modelFile
//            }
            if currentGlassesModel.isEmpty, let first = recommendedFrames.first {
//                currentGlassesModel = "rectangle.usdz"
                currentGlassesModel = "\(first.modelFile)_\(recommendedColors.first ?? "black").usdz"
            }
        }
    }
}

struct GlassesCard: View {
    let glasses: GlassesModel
    let isSelected: Bool
    let isRecommended: Bool
    let recommendedColors: [String]
    @Binding var currentGlassesModel: String
    @State var selectedColorIndex: Int
    let onSelect: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(red: 0.77, green: 0.47, blue: 0.47), lineWidth: isSelected ? 2 : 0)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 90)
                        .overlay(
                            Image(systemName: "eyeglasses")
                                .resizable()
                                .scaledToFit()
                                .padding(20)
                                .foregroundColor(.gray)
                        )

                    Text(glasses.name)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(glasses.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()

                VStack(spacing: 12) {
                    ForEach(Array(recommendedColors.enumerated()), id: \.offset) { index, color in
                        Circle()
                            .fill(mapColorToFrameColor(recommendedColors[index]))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(index == selectedColorIndex ? Color(red: 0.77, green: 0.47, blue: 0.47) : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedColorIndex = index
                                let color = recommendedColors[selectedColorIndex]
                                currentGlassesModel = "\(glasses.modelFile)_\(color).usdz"
                                print("warna", mapColorToFrameColor(recommendedColors[index]))
                            }
                    }
                }
                .padding(.trailing, 16)
            }
        }
        .frame(width: 280, height: 180)
        .padding(.top, 20)
        .onTapGesture {
            onSelect() // 👈 Call when tapped
        }
    }
    
    private func mapColorToFrameColor(_ colorName: String) -> Color {
            let lowercased = colorName.lowercased()
            
            switch lowercased {
            case "black":
                return .blackAsset
            case "brown":
                return .brownAsset
            case "darkBrown":
                return .darkBrownAsset
            case "blue":
                return .blueAsset
            case "gold":
                return .goldAsset
            case "darkRed":
                return .darkRedAsset
            case "grey":
                return .greyAsset
            default:
                return .black
            }
        }
}





struct GlassesModel {
    let name: String
    let description: String
    let modelFile: String
    let frameColors: [GlassesColor]
}

enum GlassesColor {
    case black, brown, clear
}
