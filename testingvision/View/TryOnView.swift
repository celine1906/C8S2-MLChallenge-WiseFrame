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
    @State private var currentGlassesModel = "round.usdc"
    @State private var showingARView = true
    
    // Glasses data
    let glassesOptions = [
        GlassesModel(
            name: "Rectangle",
            description: "Helps adds structure and definition which can help balance the softer features around your face, more explanation about the glasses.",
            modelFile: "rectangle.usdc",
            frameColors: [.black, .brown, .clear]
        ),
        GlassesModel(
            name: "Round",
            description: "Classic round frames that suit most face shapes and provide a vintage look.",
            modelFile: "round.usdc",
            frameColors: [.black, .brown, .clear]
        ),
        GlassesModel(
            name: "Square",
            description: "Bold square frames perfect for adding structure to softer facial features.",
            modelFile: "square.usdc",
            frameColors: [.black, .brown, .clear]
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Try-on")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Dismiss()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // AR Camera View
                ZStack {
                    if showingARView {
                        GlassesARViewRepresentable(selectedModel: currentGlassesModel)
                            .frame(height: geometry.size.height * 0.6)
                            .cornerRadius(20)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: geometry.size.height * 0.6)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .overlay(
                                Text("AR View Loading...")
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    // Page indicator dots
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            ForEach(0..<glassesOptions.count, id: \.self) { index in
                                Circle()
                                    .fill(index == selectedGlassesIndex ? Color.pink : Color.gray.opacity(0.4))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                
                // Glasses Selection Carousel
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(Array(glassesOptions.enumerated()), id: \.offset) { index, glasses in
                            GlassesCard(
                                glasses: glasses,
                                isSelected: index == selectedGlassesIndex
                            )
                            .onTapGesture {
                                selectedGlassesIndex = index
                                currentGlassesModel = glasses.modelFile
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                Spacer()
            }
        }
        .background(Color(.systemBackground))
    }
}

struct GlassesCard: View {
    let glasses: GlassesModel
    let isSelected: Bool
    @State private var selectedColorIndex = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Glasses Image
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.gray.opacity(0.1))
                .frame(width: 280, height: 120)
                .overlay(
                    Image(systemName: "eyeglasses")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                )
            
            // Color Options
            HStack(spacing: 12) {
                ForEach(Array(glasses.frameColors.enumerated()), id: \.offset) { index, color in
                    Circle()
                        .fill(colorForGlasses(color))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(index == selectedColorIndex ? Color.pink : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            selectedColorIndex = index
                        }
                }
            }
            
            // Glasses Info
            VStack(alignment: .leading, spacing: 6) {
                Text(glasses.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(glasses.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .navigationBarHidden(true)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: isSelected ? .pink.opacity(0.3) : .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2)
        )
        .frame(width: 300)
    }
    
    private func colorForGlasses(_ color: GlassesColor) -> Color {
        switch color {
        case .black:
            return .black
        case .brown:
            return .brown
        case .clear:
            return .gray.opacity(0.3)
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

