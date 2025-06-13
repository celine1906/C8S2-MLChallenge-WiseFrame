//
//  FacialLandmarkView.swift
//  testingvision
//
//  Created by Christian Luis Efendy on 11/06/25.
//

import SwiftUI
import AVFoundation
import Vision

struct FacialLandmarksView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> FacialLandmarksViewController {
        return FacialLandmarksViewController()
    }
    
    func updateUIViewController(_ uiViewController: FacialLandmarksViewController, context: Context) {
    }
}

class FacialLandmarksViewController: UIViewController {
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var landmarkLayer: CAShapeLayer!
    private var boundingBoxLayer: CAShapeLayer!
    private var landmarkCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupLayers()
        setupLandmarkCountLabel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let videoCaptureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: .video, position: .front) else { return }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    private func setupLayers() {
        // Bounding box layer
        boundingBoxLayer = CAShapeLayer()
        boundingBoxLayer.strokeColor = UIColor.green.cgColor
        boundingBoxLayer.lineWidth = 3.0
        boundingBoxLayer.fillColor = UIColor.clear.cgColor
        view.layer.addSublayer(boundingBoxLayer)
        
        // Landmarks layer
        landmarkLayer = CAShapeLayer()
        landmarkLayer.strokeColor = UIColor.red.cgColor
        landmarkLayer.lineWidth = 2.0
        landmarkLayer.fillColor = UIColor.clear.cgColor
        view.layer.addSublayer(landmarkLayer)
    }
    
    private func setupLandmarkCountLabel() {
        landmarkCountLabel = UILabel()
        landmarkCountLabel.translatesAutoresizingMaskIntoConstraints = false
        landmarkCountLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        landmarkCountLabel.textColor = UIColor.white
        landmarkCountLabel.textAlignment = .center
        landmarkCountLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        landmarkCountLabel.layer.cornerRadius = 10
        landmarkCountLabel.clipsToBounds = true
        landmarkCountLabel.text = "Landmarks: 0"
        
        view.addSubview(landmarkCountLabel)
        
        NSLayoutConstraint.activate([
            landmarkCountLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            landmarkCountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            landmarkCountLabel.widthAnchor.constraint(equalToConstant: 150),
            landmarkCountLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func detectFaceLandmarks(in image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest { (request, error) in
            DispatchQueue.main.async {
                if let results = request.results as? [VNFaceObservation] {
                    self.handleFaceDetectionResults(results)
                } else {
                    self.clearLandmarks()
                }
            }
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        
        do {
            try imageRequestHandler.perform([faceDetectionRequest])
        } catch {
            print("Failed to perform face detection: \(error)")
        }
    }
    
    private func handleFaceDetectionResults(_ results: [VNFaceObservation]) {
        guard let result = results.first,
              let landmarks = result.landmarks else {
            clearLandmarks()
            return
        }
        
        drawBoundingBox(result.boundingBox)
        drawLandmarks(landmarks, boundingBox: result.boundingBox)
        updateLandmarkCount(landmarks)
    }
    
    private func drawBoundingBox(_ boundingBox: CGRect) {
        let size = previewLayer.bounds.size
        let faceBounds = VNImageRectForNormalizedRect(boundingBox, Int(size.width), Int(size.height))
        
        // Expand bounding box by 30% to better fit the face
        let expandFactor: CGFloat = 0.3
        let expandedWidth = faceBounds.width * (1 + expandFactor)
        let expandedHeight = faceBounds.height * (1 + expandFactor)
        let expandedX = faceBounds.origin.x - (expandedWidth - faceBounds.width) / 2
        let expandedY = faceBounds.origin.y - (expandedHeight - faceBounds.height) / 2
        
        let boundingBoxRect = CGRect(
            x: expandedX,
            y: size.height - expandedY - expandedHeight,
            width: expandedWidth,
            height: expandedHeight
        )
        
        let boundingBoxPath = UIBezierPath(rect: boundingBoxRect)
        boundingBoxLayer.path = boundingBoxPath.cgPath
    }
    
    private func drawLandmarks(_ landmarks: VNFaceLandmarks2D, boundingBox: CGRect) {
        let path = UIBezierPath()
        let size = previewLayer.bounds.size
        let faceBounds = VNImageRectForNormalizedRect(boundingBox, Int(size.width), Int(size.height))
        
        // Draw face contour as connected outline
        drawFaceContour(landmarks.faceContour, path: path, faceBounds: faceBounds, viewSize: size)
        
        // Draw other landmark regions
        drawLandmarkRegion(landmarks.leftEye, path: path, faceBounds: faceBounds, viewSize: size)
        drawLandmarkRegion(landmarks.rightEye, path: path, faceBounds: faceBounds, viewSize: size)
        drawLandmarkRegion(landmarks.leftEyebrow, path: path, faceBounds: faceBounds, viewSize: size)
        drawLandmarkRegion(landmarks.rightEyebrow, path: path, faceBounds: faceBounds, viewSize: size)
        drawLandmarkRegion(landmarks.nose, path: path, faceBounds: faceBounds, viewSize: size)
        drawLandmarkRegion(landmarks.noseCrest, path: path, faceBounds: faceBounds, viewSize: size)
        drawLandmarkRegion(landmarks.medianLine, path: path, faceBounds: faceBounds, viewSize: size)
        drawLandmarkRegion(landmarks.outerLips, path: path, faceBounds: faceBounds, viewSize: size)
        drawLandmarkRegion(landmarks.innerLips, path: path, faceBounds: faceBounds, viewSize: size)
        drawLandmarkRegion(landmarks.leftPupil, path: path, faceBounds: faceBounds, viewSize: size)
        drawLandmarkRegion(landmarks.rightPupil, path: path, faceBounds: faceBounds, viewSize: size)
        
        landmarkLayer.path = path.cgPath
    }
    
    private func drawFaceContour(_ region: VNFaceLandmarkRegion2D?, path: UIBezierPath, faceBounds: CGRect, viewSize: CGSize) {
        guard let region = region else { return }
        
        let points = region.normalizedPoints
        guard points.count > 0 else { return }
        
        // Draw face contour as connected line
        let firstPoint = points[0]
        let startPoint = CGPoint(
            x: faceBounds.origin.x + firstPoint.x * faceBounds.width,
            y: viewSize.height - (faceBounds.origin.y + firstPoint.y * faceBounds.height)
        )
        
        path.move(to: startPoint)
        
        for i in 1..<points.count {
            let point = points[i]
            let facePoint = CGPoint(
                x: faceBounds.origin.x + point.x * faceBounds.width,
                y: viewSize.height - (faceBounds.origin.y + point.y * faceBounds.height)
            )
            path.addLine(to: facePoint)
        }
        
        // Draw points as small circles
        for point in points {
            let facePoint = CGPoint(
                x: faceBounds.origin.x + point.x * faceBounds.width,
                y: viewSize.height - (faceBounds.origin.y + point.y * faceBounds.height)
            )
            let circle = UIBezierPath(arcCenter: facePoint, radius: 2, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            path.append(circle)
        }
    }
    
    private func drawLandmarkRegion(_ region: VNFaceLandmarkRegion2D?, path: UIBezierPath, faceBounds: CGRect, viewSize: CGSize) {
        guard let region = region else { return }
        
        let points = region.normalizedPoints
        
        for i in 0..<points.count {
            let point = points[i]
            let facePoint = CGPoint(
                x: faceBounds.origin.x + point.x * faceBounds.width,
                y: viewSize.height - (faceBounds.origin.y + point.y * faceBounds.height)
            )
            
            if i == 0 {
                path.move(to: facePoint)
            } else {
                path.addLine(to: facePoint)
            }
            
            // Draw small circles for individual landmark points
            let circle = UIBezierPath(arcCenter: facePoint, radius: 1.5, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            path.append(circle)
        }
    }
    
    private func updateLandmarkCount(_ landmarks: VNFaceLandmarks2D) {
        var totalLandmarks = 0
        
        totalLandmarks += landmarks.allPoints?.pointCount ?? 0
        totalLandmarks += landmarks.faceContour?.pointCount ?? 0
        totalLandmarks += landmarks.leftEye?.pointCount ?? 0
        totalLandmarks += landmarks.rightEye?.pointCount ?? 0
        totalLandmarks += landmarks.leftEyebrow?.pointCount ?? 0
        totalLandmarks += landmarks.rightEyebrow?.pointCount ?? 0
        totalLandmarks += landmarks.nose?.pointCount ?? 0
        totalLandmarks += landmarks.noseCrest?.pointCount ?? 0
        totalLandmarks += landmarks.medianLine?.pointCount ?? 0
        totalLandmarks += landmarks.outerLips?.pointCount ?? 0
        totalLandmarks += landmarks.innerLips?.pointCount ?? 0
        totalLandmarks += landmarks.leftPupil?.pointCount ?? 0
        totalLandmarks += landmarks.rightPupil?.pointCount ?? 0
        
        landmarkCountLabel.text = "Landmarks: \(totalLandmarks)"
        print("Total facial landmarks detected: \(totalLandmarks)")
    }
    
    private func clearLandmarks() {
        landmarkLayer.path = nil
        boundingBoxLayer.path = nil
        landmarkCountLabel.text = "Landmarks: 0"
    }
}

extension FacialLandmarksViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        detectFaceLandmarks(in: pixelBuffer)
    }
}
