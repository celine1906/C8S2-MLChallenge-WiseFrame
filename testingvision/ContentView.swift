import SwiftUI
import AVFoundation
import Vision
import CoreML
import UIKit

// MARK: - Main App View
struct ContentView: View {
    var body: some View {
        NavigationStack {
            CameraView()
        }
    }
}
