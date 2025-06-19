//
//  RecommendationViewModel.swift
//  testingvision
//
//  Created by Regina Celine Adiwinata on 19/06/25.
//

import Foundation
//import SwiftUI

class RecommendationViewModel: ObservableObject {
    
    var recommendedGlasses: [Int] = []
    var recommendedColors: [String] = []
    
      
      func getRecommendedGlasses(for faceShape: String) -> [Int] {
          var recommended: [Int] = []
          
          switch faceShape {
          case "oval":
              // Oval faces can wear most styles
              recommended = [0, 1, 2, 3, 4, 6] // Rectangle, Round, Aviator, Cat Eye, Square, Geometric
              
          case "round":
              // Angular frames to add structure
              recommended = [0, 2, 4, 6] // Rectangle, Aviator, Square, Geometric
              
          case "square":
              // Soft, curved frames to balance sharp angles
              recommended = [1, 3, 5] // Round, Cat Eye, Oval
              
          case "oblong":
              // Wide frames to balance length
              recommended = [0, 2, 4] // Rectangle, Aviator, Square
              
          case "heart":
              // Bottom-heavy frames to balance wider forehead
              recommended = [1, 3, 5] // Round, Cat Eye, Oval
              
          case "triangle":
              // Top-heavy frames to balance wider jaw
              recommended = [0, 2, 3] // Rectangle, Aviator, Cat Eye
              
          case "diamond":
              // Frames that highlight eyes and soften cheekbones
              recommended = [1, 3, 5] // Round, Cat Eye, Oval
              
          default:
              // Default recommendations
              recommended = [0, 1, 4] // Rectangle, Round, Square
          }
          
          return recommended
      }
      
      func getRecommendedColors(for skinTone: String) -> [String] {
          
//          let skinTone = topSkinTone.key.lowercased()
          
          switch skinTone {
          case "light":
              // Light skin tone - cool undertones
              return ["blue", "black", "gold"]
              
          case "mid-light":
              // Medium light with warm undertones
              return ["brown", "darkRed", "blue"]
              
          case "mid-dark":
              // Medium light with cool undertones
              return ["grey", "black", "darkBrown"]
              
          case "dark":
              // Deep tone
              return ["black", "gold", "blue"]
              
          default:
              return ["black", "brown", "darkRed"]
          }
      }
}
