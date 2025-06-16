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

import UIKit
import ARKit
import SceneKit
import SwiftUI

class GlassesARViewController: UIViewController, ARSCNViewDelegate {
    
    let sceneView = ARSCNView(frame: .zero)
    var glassesNode: SCNNode?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(sceneView)
        sceneView.frame = view.bounds
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true

        // Konfigurasi Face Tracking
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // Load model kacamata
        guard let scene = SCNScene(named: "aviators.usdc"),
              let glasses = scene.rootNode.childNodes.first else {
            print("❌ Gagal load model")
            return
        }

        // Simpan glassesNode untuk ditambahkan ke anchor wajah
        self.glassesNode = glasses
    }

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let device = sceneView.device,
              anchor is ARFaceAnchor else { return nil }

        let node = SCNNode()

        // Occlusion: Geometri wajah
        let faceGeometry = ARSCNFaceGeometry(device: device)!
        faceGeometry.firstMaterial?.colorBufferWriteMask = []
        faceGeometry.firstMaterial?.isDoubleSided = true
        let faceOcclusionNode = SCNNode(geometry: faceGeometry)
        faceOcclusionNode.name = "faceOcclusion"
        node.addChildNode(faceOcclusionNode)

        // Occlusion: Bola mata
        let leftEyeOcclusion = createEyeOccluder(name: "leftEye")
        let rightEyeOcclusion = createEyeOccluder(name: "rightEye")
        node.addChildNode(leftEyeOcclusion)
        node.addChildNode(rightEyeOcclusion)

        // Kacamata
        if let glasses = glassesNode?.clone() {
            node.addChildNode(glasses)
        }

        return node
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }

        // Update face geometry
        if let faceGeometry = node.childNode(withName: "faceOcclusion", recursively: false)?.geometry as? ARSCNFaceGeometry {
            faceGeometry.update(from: faceAnchor.geometry)
        }

        // Update posisi bola mata
        if let leftEye = node.childNode(withName: "leftEye", recursively: false) {
            leftEye.simdTransform = faceAnchor.leftEyeTransform
        }
        if let rightEye = node.childNode(withName: "rightEye", recursively: false) {
            rightEye.simdTransform = faceAnchor.rightEyeTransform
        }
    }

    // MARK: - Eye Occluder Helper
    func createEyeOccluder(name: String) -> SCNNode {
        let eyeSphere = SCNSphere(radius: 0.013)
        let material = SCNMaterial()
        material.colorBufferWriteMask = []
        material.isDoubleSided = true
        eyeSphere.firstMaterial = material

        let eyeNode = SCNNode(geometry: eyeSphere)
        eyeNode.name = name
        return eyeNode
    }
}

// MARK: - SwiftUI Representable
struct GlassesARViewRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GlassesARViewController {
        return GlassesARViewController()
    }
    
    func updateUIViewController(_ uiViewController: GlassesARViewController, context: Context) {}
}
