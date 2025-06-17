//
//  ARView.swift
//  testingvision
//
//  Created by Regina Celine Adiwinata on 16/06/25.
//

//
//  ARView.swift
//  testingvision
//
//  Created by Regina Celine Adiwinata on 16/06/25.
//

import SwiftUI
import RealityKit
import ARKit
import simd


class GlassesRealityARView: ARView, ARSessionDelegate {
    
    var faceAnchorEntity: AnchorEntity?
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        
        // Set AR session delegate
        self.session.delegate = self
        
        // Run face tracking config
        let config = ARFaceTrackingConfiguration()
        config.isLightEstimationEnabled = true
        self.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        // Add face anchor
        let anchor = AnchorEntity(.face)
        self.faceAnchorEntity = anchor
        self.scene.addAnchor(anchor)
        
        // Load glasses
        loadGlasses(into: anchor)
        
        // Add occlusion (fake — just black material)
        addFakeFaceOcclusion(to: anchor)
    }

    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadGlasses(into anchor: AnchorEntity) {
        do {
            let glassesEntity = try ModelEntity.loadModel(named: "rectangle.usdz")
            glassesEntity.setScale(SIMD3<Float>(0.95, 0.95, 0.95), relativeTo: nil)
            glassesEntity.position = [0, 0, 0.0009] // Adjust to fit face
            let rotationAngle = Float(1) * .pi / 180
            glassesEntity.transform.rotation = simd_quatf(angle: rotationAngle, axis: [0, 1, 0])
            anchor.addChild(glassesEntity)
        } catch {
            print("❌ Failed to load glasses model: \(error)")
        }
    }

    private func addFakeFaceOcclusion(to anchor: AnchorEntity) {
        let occluder = ModelEntity(mesh: .generateSphere(radius: 0.1), materials: [OcclusionMaterial()])
        occluder.position = [0, 0, 0] // Close to face
        occluder.scale = [0.4, 0.4, 0] // Flattened to approximate face
        anchor.addChild(occluder)
    }
}


// MARK: - SwiftUI Representable
struct GlassesARViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> GlassesRealityARView {
        return GlassesRealityARView(frame: .zero)
    }

    func updateUIView(_ uiView: GlassesRealityARView, context: Context) {}
}

