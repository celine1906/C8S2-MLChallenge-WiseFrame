import SwiftUI
import AVFoundation
import Vision
import CoreML
import UIKit

//// MARK: - Main App View
//struct ContentView: View {
//    var body: some View {
//        NavigationStack {
//            WelcomePages()
//        }
//    }
//}


struct ContentView: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            WelcomePages(path: $path)
                .navigationDestination(for: String.self) { route in
                    switch route {
                    case "GenderView":
                        GenderView(path: $path)
                    case "CameraView":
                        CameraView(path: $path)
                    case "RecommendationView":
//                        RecommendationView(path: $path)
                        RecommendationView(
                                path: $path,
                                image: nil,
                                result2: [:],
                                finalResults: []
                            )
                    case "TryOnView":
                        GlassesTryOnView(path: $path, recommendedFrameIndexes: [], recommendedColors: [])
                    default:
                        EmptyView()
                    }
                }
        }
    }
}
