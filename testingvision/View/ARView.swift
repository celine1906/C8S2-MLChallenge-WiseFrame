//
//  ARView.swift
//  testingvision
//
//  Created by Regina Celine Adiwinata on 16/06/25.
//

import SwiftUI
import RealityKit
import ARKit
import Combine

class GlassesRealityARView: ARView, ARSessionDelegate {
    
    var faceAnchorEntity: AnchorEntity?
    var glassesEntity: ModelEntity?
    var currentModelName: String = "square_black_light.usdz"
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        self.session.delegate = self
        
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = true
        self.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        let anchor = AnchorEntity(.face)
        self.faceAnchorEntity = anchor
        self.scene.addAnchor(anchor)
        
        // Load initial model
        loadGlassesModel(named: currentModelName)
        
        // Optional: add occlusion
        addFakeFaceOcclusion(to: anchor)
    }

    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadGlassesModel(named modelName: String) {
        guard modelName != currentModelName || glassesEntity == nil else { return }

        do {
            let newGlasses = try ModelEntity.loadModel(named: modelName)
            newGlasses.name = "glasses"
            newGlasses.setScale(SIMD3<Float>(0.95, 0.95, 0.95), relativeTo: nil)
            newGlasses.position = [0, 0, 0.0009]
            newGlasses.transform.rotation = simd_quatf(angle: Float(1) * .pi / 180, axis: [1, 0, 0])

            // Remove previous
            glassesEntity?.removeFromParent()
            glassesEntity = newGlasses
            faceAnchorEntity?.addChild(newGlasses)

            currentModelName = modelName
        } catch {
            print("❌ Failed to load \(modelName): \(error)")
        }
    }

    private func addFakeFaceOcclusion(to anchor: AnchorEntity) {
        let occluder = ModelEntity(
            mesh: .generateSphere(radius: 0.1),
            materials: [OcclusionMaterial()]
        )
        occluder.position = [0, 0, 0]
        occluder.scale = [0.4, 0.4, 0]
        anchor.addChild(occluder)
    }
}


struct GlassesARViewRepresentable: UIViewRepresentable {
    let selectedModel: String

    func makeUIView(context: Context) -> GlassesRealityARView {
        let view = GlassesRealityARView(frame: .zero)
        view.loadGlassesModel(named: selectedModel)
        return view
    }

    func updateUIView(_ uiView: GlassesRealityARView, context: Context) {
        uiView.loadGlassesModel(named: selectedModel)
    }
}
