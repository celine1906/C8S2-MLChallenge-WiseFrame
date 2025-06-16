//
//  ARContainerView.swift
//  testingvision
//
//  Created by Regina Celine Adiwinata on 16/06/25.
//

import SwiftUI
import RealityKit

struct GlassesARContainerView: View {
    @StateObject private var viewModel = ARViewModel()

    var body: some View {
        VStack {
            if viewModel.checkFaceTrackingAvailability() {
                ARViewContainer()
                    .edgesIgnoringSafeArea(.all)
            } else {
                Text("Face tracking tidak didukung di perangkat ini.")
                    .foregroundColor(.red)
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        return GlassesARView(frame: .zero)
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // bisa menambahkan logic update nanti jika diperlukan
    }
}
