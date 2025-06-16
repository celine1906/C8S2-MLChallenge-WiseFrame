//
//  ARView.swift
//  testingvision
//
//  Created by Regina Celine Adiwinata on 16/06/25.
//

import SwiftUI
import RealityKit
import ARKit

class GlassesARView: ARView {
    
    required init(frame: CGRect) {
        super.init(frame: frame)

        // Konfigurasi AR
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        // Deteksi wajah
        let faceAnchor = AnchorEntity(.face)
        self.scene.anchors.append(faceAnchor)

        // Load asset kacamata
        guard let glasses = try? Entity.loadModel(named: "Glasses") else {
            print("❌ Gagal load glasses.usdz")
            return
        }

        if let modelEntity = glasses as? ModelEntity {
            modelEntity.position = SIMD3<Float>(repeating: 0)
            modelEntity.scale = SIMD3<Float>(repeating: 0.1)
        }

        // Tambahkan ke face anchor
        faceAnchor.addChild(glasses)
    }

    @objc required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
