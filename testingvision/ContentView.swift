import SwiftUI
import AVFoundation
import Vision
import CoreML
import UIKit

// MARK: - Main App View
struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var predictions: [(String, Double)] = []
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var pictureCount = 0
    @State private var showResults = false
    @State private var finalResults: [(String, Double, Int)] = []
    
    private let totalPictures = 6
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreview(cameraManager: cameraManager)
                .ignoresSafeArea()
            
            VStack {
                // Picture Counter (Top Right)
                HStack {
                    Spacer()
                    VStack {
                        Text("\(pictureCount)/\(totalPictures)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(20)
                        
                        if pictureCount < totalPictures && pictureCount > 0 {
                            Text("Keep going!")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.7))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 50)
                }
                
                Spacer()
                
                // Instructions or Results
                VStack(spacing: 15) {
                    if showResults {
                        // Final Results Display
                        VStack(spacing: 10) {
                            Text("Your Face Shape Results")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.bottom, 5)
                            
                            ForEach(Array(finalResults.enumerated()), id: \.offset) { index, result in
                                HStack {
                                    Text("\(index + 1).")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text(result.0.capitalized)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("\(Int(result.1))%")
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                        Text("(\(result.2) votes)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(10)
                            }
                            
                            // Reset Button
                            Button("Take New Photos") {
                                resetSession()
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                            .padding(.top, 10)
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(15)
                    } else {
                        // Instructions
                        VStack(spacing: 8) {
                            if pictureCount == 0 {
                                Text("Take 6 photos from different angles")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Try: front, slight left, slight right, slight up, slight down, neutral")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            } else if pictureCount < totalPictures {
                                Text("Picture \(pictureCount + 1) of \(totalPictures)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Try a different angle or expression")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(15)
                    }
                    
                    // Capture Button (only show if not showing results)
                    if !showResults {
                        Button(action: capturePhoto) {
                            ZStack {
                                Circle()
                                    .fill(pictureCount >= totalPictures ? Color.green : Color.white)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 90, height: 90)
                                
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: pictureCount >= totalPictures ? .white : .black))
                                } else if pictureCount >= totalPictures {
                                    Image(systemName: "checkmark")
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(isProcessing)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .onAppear {
            cameraManager.requestPermission()
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func capturePhoto() {
        if pictureCount >= totalPictures {
            // Calculate final results
            calculateFinalResults()
            return
        }
        
        isProcessing = true
        cameraManager.capturePhoto { image in
            guard let image = image else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.alertMessage = "Failed to capture photo"
                    self.showAlert = true
                }
                return
            }
            
            // Process the captured image
            FaceShapePredictor.shared.predictFaceShape(from: image) { result in
                DispatchQueue.main.async {
                    self.isProcessing = false
                    
                    switch result {
                    case .success(let (predictedShape, confidence)):
                        self.predictions.append((predictedShape, confidence))
                        self.pictureCount += 1
                        
                        // Show results after 6 pictures
                        if self.pictureCount >= self.totalPictures {
                            self.calculateFinalResults()
                        }
                        
                    case .failure(let error):
                        self.alertMessage = error.localizedDescription
                        self.showAlert = true
                    }
                }
            }
        }
    }
    
    private func calculateFinalResults() {
        // Group predictions by face shape and calculate stats
        var shapeStats: [String: (totalConfidence: Double, count: Int)] = [:]
        
        for (shape, confidence) in predictions {
            if let existing = shapeStats[shape] {
                shapeStats[shape] = (existing.totalConfidence + confidence, existing.count + 1)
            } else {
                shapeStats[shape] = (confidence, 1)
            }
        }
        
        // Calculate average confidence and sort by count, then by average confidence
        let sortedResults = shapeStats.map { (shape, stats) in
            let avgConfidence = stats.totalConfidence / Double(stats.count)
            return (shape, avgConfidence, stats.count)
        }.sorted { first, second in
            if first.2 != second.2 {
                return first.2 > second.2  // Sort by count first
            }
            return first.1 > second.1  // Then by average confidence
        }
        
        // Take top 3 results
        finalResults = Array(sortedResults.prefix(3))
        showResults = true
    }
    
    private func resetSession() {
        predictions = []
        pictureCount = 0
        showResults = false
        finalResults = []
    }
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?
    
    override init() {
        super.init()
        setupSession()
    }
    
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                DispatchQueue.main.async {
                    self.startSession()
                }
            }
        }
    }
    
    private func setupSession() {
        session.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
    }
    
    func startSession() {
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        captureCompletion = completion
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

// MARK: - Camera Delegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            captureCompletion?(nil)
            return
        }
        
        captureCompletion?(image)
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraManager.session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Face Shape Predictor
class FaceShapePredictor {
    static let shared = FaceShapePredictor()
    private var model: MLModel?
    
    private init() {
        loadModel()
    }
    
    private func loadModel() {
        print("\(#function)")
        guard let model = try? randomforest(configuration: MLModelConfiguration()) else {
            print("Failed to load ML model")
            return
        }
        
        self.model = model.model
    }
    
    func predictFaceShape(from image: UIImage, completion: @escaping (Result<(String, Double), Error>) -> Void) {
        print("\(#function)")
        guard let model = model else {
            completion(.failure(PredictionError.modelNotLoaded))
            return
        }
        
        // Extract landmarks from the image
        extractLandmarks(from: image) { landmarks in
            guard let landmarks = landmarks else {
                completion(.failure(PredictionError.landmarkExtractionFailed))
                return
            }
            
            // Create feature array for prediction
            guard let features = self.createFeatureArray(from: landmarks) else {
                completion(.failure(PredictionError.featureCreationFailed))
                return
            }
            
            // Make prediction
            do {
                let prediction = try model.prediction(from: features)
                
                // Extract prediction result
                if let classLabelOutput = prediction.featureValue(for: "label")?.stringValue,
                   let classProbability = prediction.featureValue(for: "labelProbability")?.dictionaryValue {
                    
                    let confidence = classProbability[classLabelOutput]?.doubleValue ?? 0.0
                    completion(.success((classLabelOutput, confidence * 100))) // Convert to percentage
                } else {
                    completion(.failure(PredictionError.predictionFailed))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func extractLandmarks(from image: UIImage, completion: @escaping ([CGPoint]?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let request = VNDetectFaceLandmarksRequest { request, error in
            guard let results = request.results as? [VNFaceObservation],
                  let face = results.first,
                  let landmarks = face.landmarks else {
                completion(nil)
                return
            }
            
            let processedLandmarks = self.processFaceLandmarks(landmarks)
            completion(processedLandmarks)
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Error performing landmark detection: \(error)")
                completion(nil)
            }
        }
    }
    
    private func processFaceLandmarks(_ landmarks: VNFaceLandmarks2D) -> [CGPoint] {
        var coordinates: [CGPoint] = []
        
        // Add landmarks in the same order as your training data
        if let faceContour = landmarks.faceContour {
            coordinates.append(contentsOf: faceContour.normalizedPoints)
        }
        if let leftEyebrow = landmarks.leftEyebrow {
            coordinates.append(contentsOf: leftEyebrow.normalizedPoints)
        }
        if let rightEyebrow = landmarks.rightEyebrow {
            coordinates.append(contentsOf: rightEyebrow.normalizedPoints)
        }
        if let nose = landmarks.nose {
            coordinates.append(contentsOf: nose.normalizedPoints)
        }
        if let noseCrest = landmarks.noseCrest {
            coordinates.append(contentsOf: noseCrest.normalizedPoints)
        }
        if let leftEye = landmarks.leftEye {
            coordinates.append(contentsOf: leftEye.normalizedPoints)
        }
        if let rightEye = landmarks.rightEye {
            coordinates.append(contentsOf: rightEye.normalizedPoints)
        }
        if let outerLips = landmarks.outerLips {
            coordinates.append(contentsOf: outerLips.normalizedPoints)
        }
        if let innerLips = landmarks.innerLips {
            coordinates.append(contentsOf: innerLips.normalizedPoints)
        }
        if let leftPupil = landmarks.leftPupil {
            coordinates.append(contentsOf: leftPupil.normalizedPoints)
        }
        if let rightPupil = landmarks.rightPupil {
            coordinates.append(contentsOf: rightPupil.normalizedPoints)
        }
        if let medianLine = landmarks.medianLine {
            coordinates.append(contentsOf: medianLine.normalizedPoints)
        }
        
        // Ensure exactly 68 points
        while coordinates.count < 68 {
            coordinates.append(CGPoint(x: 0, y: 0))
        }
        if coordinates.count > 68 {
            coordinates = Array(coordinates.prefix(68))
        }
        
        return coordinates
    }
    
    private func createFeatureArray(from landmarks: [CGPoint]) -> MLFeatureProvider? {
        var featureDict: [String: Any] = [:]
        
        // Create feature dictionary with the same format as training data
        for (index, point) in landmarks.enumerated() {
            featureDict["landmark_\(index)_x"] = point.x
            featureDict["landmark_\(index)_y"] = point.y
        }
        
        do {
            return try MLDictionaryFeatureProvider(dictionary: featureDict)
        } catch {
            print("Error creating feature provider: \(error)")
            return nil
        }
    }
}

// MARK: - Prediction Errors
enum PredictionError: LocalizedError {
    case modelNotLoaded
    case landmarkExtractionFailed
    case featureCreationFailed
    case predictionFailed
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "ML model could not be loaded"
        case .landmarkExtractionFailed:
            return "Could not detect face landmarks"
        case .featureCreationFailed:
            return "Could not create features for prediction"
        case .predictionFailed:
            return "Prediction failed"
        }
    }
}


