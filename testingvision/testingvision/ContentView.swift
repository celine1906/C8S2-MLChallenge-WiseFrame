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
    
    // Updated scaler parameters from your JSON file (161 features: 136 landmarks + 25 geometric)
    private let scalerCenter = [
        0.9249245681825259, 0.73053, 0.924774, 0.619261, 0.9142703654494034, 0.50729, 0.895173, 0.39657549763533684, 0.8581103622416848, 0.2901739343845622, 0.7951964283781685, 0.19653790559777357, 0.7128343574553303, 0.117926, 0.618973, 0.05613, 0.5090517869023728, 0.031282, 0.399643, 0.053691, 0.3068673255181194, 0.113464, 0.22512870826339113, 0.190998, 0.16022, 0.28384805315237116, 0.1215325435055138, 0.3887179866911778, 0.09982206471862058, 0.498181, 0.0862181848882166, 0.609232, 0.082879, 0.7198051116235726, 0.1488712789985092, 0.8091220424259683, 0.27672513908585233, 0.8541348612214916, 0.409367, 0.825574, 0.404098, 0.7823962768123194, 0.2782700362119558, 0.8057743201045364, 0.1535310376069401, 0.7835586443537632, 0.857690063309676, 0.825639, 0.7243588470295614, 0.8631036562399907, 0.589123, 0.8309328970422872, 0.596615, 0.7855039092477595, 0.724433, 0.8155096849915086, 0.8535153566330861, 0.799897, 0.5040793379468232, 0.653062084200975, 0.413273, 0.539451421419228, 0.412195, 0.4507216110556312, 0.460018, 0.444966, 0.506764, 0.432325, 0.5543797833481241, 0.445981, 0.6012196072652067, 0.4530161427064134, 0.597964, 0.5404095224090675, 0.503159, 0.731953, 0.5040793379468232, 0.653062084200975, 0.505288, 0.5713606138090571, 0.5060699880469826, 0.492061, 0.435659477940055, 0.486893, 0.577745, 0.48828459410948494, 0.23633736169601713, 0.720501, 0.28364, 0.746646, 0.35593863535642195, 0.739823280077479, 0.398933, 0.70591, 0.34885, 0.7021886091708032, 0.28147507772570246, 0.701375, 0.7702970231615909, 0.725525, 0.721847, 0.7521, 0.6502137966084445, 0.742435, 0.6072314205320379, 0.708413, 0.6576356058679992, 0.705221, 0.724639, 0.7055039441701882, 0.3810671720769033, 0.340545, 0.424772, 0.353026, 0.46931, 0.360063, 0.5068454483214901, 0.352575, 0.5454857826269314, 0.359543, 0.589563, 0.35403762115113435, 0.6334252314538668, 0.3431246197391092, 0.6732596802172327, 0.328776, 0.629783, 0.28097, 0.571832, 0.244728, 0.507229, 0.2327080601805825, 0.4426348790344279, 0.24238194590935017, 0.3852190544147483, 0.27713, 0.8521420000000001, 0.8444893334419851, 1.0099398837142621, 0.850788686786739, 0.23309541033470824, 0.7082541612113942, -0.1420995, 0.443049574092185, 0.38361176177584105, 0.4889198876822343, 0.5077146019892883, 0.5256854482358746, 0.2918288135341185, 0.1329759166513359, 1.1969356250579914, 0.9903023567110782, -0.16779500986702747, 0.5227861208135326, 0.5737075481170704, -0.844126, -0.9951687099402462, 0.8355551875621035, 0.72104, 0.8350269672417429, 0.9999999881952693
    ]
    
    private let scalerScale = [
        0.05084593519203706, 0.052477962950221446, 0.04752100235831014, 0.05130890954073253, 0.04842399132853259, 0.05134634296953022, 0.05009639588602133, 0.0501489018684983, 0.04799094870977383, 0.04982500000000001, 0.04404376035090829, 0.04708137368835419, 0.04143712599367422, 0.040850588648986635, 0.04319719722119486, 0.03280942847835442, 0.043676824011500026, 0.03219137307731994, 0.04418684057711059, 0.03334539547896377, 0.045563105734063025, 0.03859204585737108, 0.0465332275348021, 0.041401999999999994, 0.04645328143780003, 0.042906, 0.048036999999999996, 0.04399148374022949, 0.045499, 0.04464405597460275, 0.04547971286633622, 0.04632984716673405, 0.048543580921467794, 0.04767387716861049, 0.035401251698618325, 0.038914113715086796, 0.036650000000000016, 0.030817852299422133, 0.04131361138122247, 0.02440709462368673, 0.036800170242220875, 0.022957478007235355, 0.03162899999999996, 0.03022290672752026, 0.03384107423311694, 0.0387018486306262, 0.03350087271556201, 0.045440791116414525, 0.03929899999999997, 0.03218280719382138, 0.043445091940171654, 0.023783830343452883, 0.038321766720274764, 0.0230044340857668, 0.033993262242817956, 0.03291948573693193, 0.031393879660716495, 0.04495504152696206, 0.026290953900272196, 0.01858780134587623, 0.015436000000000005, 0.018423602535241335, 0.017524761866909655, 0.017765606095879183, 0.01908640770261477, 0.018758620902811718, 0.022015000000000007, 0.022500684479704824, 0.021447279092304372, 0.019483969849134808, 0.022535730779265073, 0.019126581508942253, 0.02231618988249906, 0.018709869747649988, 0.02929900000000002, 0.014077000000000006, 0.026290953900272196, 0.01858780134587623, 0.027324272976922692, 0.024981602204973252, 0.028846866193471266, 0.03269677323256204, 0.021343674635601106, 0.022165332785580694, 0.02554872777247752, 0.02253477199349363, 0.026205451392438073, 0.028262242927135195, 0.027405923536073074, 0.023751454746991918, 0.025479078542798572, 0.018376294903890034, 0.02183683844620199, 0.018956339571427616, 0.022008480533920072, 0.02265946499148097, 0.024321469441942023, 0.02622800000000003, 0.025310939815664457, 0.03051373203073826, 0.026556496482361802, 0.02696962175094919, 0.02672901655424187, 0.01939702100455809, 0.023486285430517784, 0.016988969595235104, 0.022652799478359964, 0.020783498464593264, 0.023074294122358507, 0.024366927032041574, 0.027128833334533475, 0.03134128184538687, 0.020604866287122825, 0.028283596428056723, 0.01840382563232973, 0.025957000000000008, 0.017215303221096878, 0.025458075774472178, 0.017840437200573933, 0.024735235584417148, 0.020670373650447327, 0.02611840708503793, 0.026704116769283193, 0.029557904143342417, 0.03396090334749591, 0.03520940604434525, 0.03173112986931681, 0.025508705090179884, 0.027430164165891058, 0.023307841785631778, 0.024627042394226695, 0.024560009079647616, 0.028388146447130613, 0.02313800000000002, 0.033053, 0.023309857095282327, 0.04137756479211385, 0.037021971764809036, 0.06315242038448177, 0.04127218994229287, 0.013972394736138621, 0.031040000000000068, 0.018695292017898824, 0.03862416195256363, 0.03514278101934548, 0.023612965097948635, 0.00860351465233411, 0.00960489705882328, 0.00650926506147792, 0.00702486389850554, 0.046053085011547035, 0.06181685865409825, 0.023316630453462717, 0.04423410784023929, 0.0283228823126892, 0.03906891177697325, 0.008870022640967257, 0.031930527496732974, 0.05185832458962225, 0.03299278268233796, 6.178501044118434e-10
    ]
    
    // 7 classes for your updated model
    private let faceShapeClasses = ["Diamond", "Heart", "Oblong", "Oval", "Round", "Square", "Triangle"]
    
    private init() {
        loadModel()
    }
    
    private func loadModel() {
        // Try to load the 7-class model first, fall back to 5-class
        if let model = try? FaceShapeClassifier7Classes(configuration: MLModelConfiguration()) {
            self.model = model.model
            print("✅ 7-class ML model loaded successfully")
        } else if let model = try? FaceShapeClassifier(configuration: MLModelConfiguration()) {
            self.model = model.model
            print("⚠️ Fell back to 5-class ML model")
        } else {
            print("❌ Failed to load any ML model")
        }
    }
    
    func predictFaceShape(from image: UIImage, completion: @escaping (Result<(String, Double), Error>) -> Void) {
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
            
            print("📍 Extracted \(landmarks.count) landmarks")
            
            // Create processed input with geometric features and scaling
            guard let inputArray = self.createProcessedInput(from: landmarks) else {
                completion(.failure(PredictionError.featureCreationFailed))
                return
            }
            
            // Make prediction
            do {
                let prediction = try model.prediction(from: inputArray)
                
                // Try different output key names
                let possibleOutputKeys = ["Identity", "classLabel", "label", "output", "batch_normalization_9_input"]
                
                for outputKey in possibleOutputKeys {
                    if let probabilities = prediction.featureValue(for: outputKey)?.multiArrayValue {
                        let (predictedClass, confidence) = self.extractClassPrediction(from: probabilities)
                        print("✅ Prediction: \(predictedClass) with \(confidence * 100)% confidence")
                        completion(.success((predictedClass, confidence * 100)))
                        return
                    }
                }
                
                // If no output found, fail
                print("❌ No valid output found in prediction")
                completion(.failure(PredictionError.predictionFailed))
                
            } catch {
                print("❌ Prediction error: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    private func createProcessedInput(from landmarks: [CGPoint]) -> MLFeatureProvider? {
        // Step 1: Convert landmarks to flat array (136 values)
        var landmarkArray: [Double] = []
        for point in landmarks.prefix(68) {
            landmarkArray.append(Double(point.x))
            landmarkArray.append(Double(point.y))
        }
        
        // Ensure we have exactly 136 landmark values
        while landmarkArray.count < 136 {
            landmarkArray.append(0.0)
        }
        landmarkArray = Array(landmarkArray.prefix(136))
        
        // Step 2: Calculate 25 geometric features (matching Python exactly)
        let geometricFeatures = calculateEnhancedGeometricFeatures(from: landmarks)
        
        // Step 3: Combine landmarks with geometric features (136 + 25 = 161)
        var combinedFeatures = landmarkArray + geometricFeatures
        
        print("🔧 Feature breakdown:")
        print("   Landmarks: \(landmarkArray.count)")
        print("   Geometric: \(geometricFeatures.count)")
        print("   Combined: \(combinedFeatures.count)")
        
        // Step 4: Apply RobustScaler transformation: (x - center) / scale
        let expectedFeatures = min(combinedFeatures.count, scalerCenter.count, scalerScale.count)
        print("   Expected features: \(expectedFeatures)")
        
        for i in 0..<expectedFeatures {
            if scalerScale[i] != 0 {
                combinedFeatures[i] = (combinedFeatures[i] - scalerCenter[i]) / scalerScale[i]
            }
        }
        
        // Step 5: Create MLMultiArray with the processed features
        do {
            let multiArray = try MLMultiArray(shape: [1, NSNumber(value: expectedFeatures)], dataType: .double)
            
            for (index, value) in combinedFeatures.enumerated() {
                if index < expectedFeatures {
                    multiArray[index] = NSNumber(value: value)
                }
            }
            
            // Use the correct input name from JSON
            let featureDict: [String: Any] = ["input_landmarks": multiArray]
            return try MLDictionaryFeatureProvider(dictionary: featureDict)
            
        } catch {
            print("❌ Error creating input array: \(error)")
            return nil
        }
    }
    
    private func calculateEnhancedGeometricFeatures(from landmarks: [CGPoint]) -> [Double] {
        guard landmarks.count >= 68 else {
            return Array(repeating: 0.0, count: 25)
        }
        
        // Safe function to get landmark or return zero point
        func safeLandmark(_ index: Int) -> CGPoint {
            return index < landmarks.count ? landmarks[index] : CGPoint.zero
        }
        
        // Basic face dimensions using safe array operations
        let xCoords = landmarks.map { Double($0.x) }
        let yCoords = landmarks.map { Double($0.y) }
        
        guard let maxX = xCoords.max(), let minX = xCoords.min(),
              let maxY = yCoords.max(), let minY = yCoords.min() else {
            return Array(repeating: 0.0, count: 25)
        }
        
        let faceWidth = maxX - minX
        let faceHeight = maxY - minY
        let widthHeightRatio = faceHeight > 0 ? faceWidth / faceHeight : 0
        
        // Jaw measurements (landmarks 0-16)
        let jawWidth = distance(safeLandmark(0), safeLandmark(16))
        var jawYCoords: [Double] = []
        for i in 0...16 {
            jawYCoords.append(Double(safeLandmark(i).y))
        }
        let jawCurvature = jawYCoords.count > 1 ? standardDeviation(jawYCoords) : 0
        
        // Forehead measurements (landmarks 17-26)
        let foreheadWidth = distance(safeLandmark(17), safeLandmark(26))
        
        // Eye measurements
        let eyeDistance = distance(safeLandmark(36), safeLandmark(45))
        // Removed unused leftEyeWidth and rightEyeWidth variables
        
        // Nose measurements
        let noseWidth = distance(safeLandmark(31), safeLandmark(35))
        let noseLength = distance(safeLandmark(27), safeLandmark(33))
        
        // Mouth measurements
        let mouthWidth = distance(safeLandmark(48), safeLandmark(54))
        
        // Centroid calculations
        let centroidX = xCoords.reduce(0, +) / Double(xCoords.count)
        let centroidY = yCoords.reduce(0, +) / Double(yCoords.count)
        
        // Distance features - simplified to avoid complex expressions
        var distances: [Double] = []
        for landmark in landmarks {
            let dx = Double(landmark.x) - centroidX
            let dy = Double(landmark.y) - centroidY
            let dist = sqrt(dx * dx + dy * dy)
            distances.append(dist)
        }
        
        let meanDistance = distances.reduce(0, +) / Double(distances.count)
        let stdDistance = standardDeviation(distances)
        
        // Calculate ratios safely to avoid variable redefinition
        let jawToForeheadRatio: Double
        if foreheadWidth > 0 {
            jawToForeheadRatio = jawWidth / foreheadWidth
        } else {
            jawToForeheadRatio = 0
        }
        
        let faceAspectRatio: Double
        if faceWidth > 0 {
            faceAspectRatio = faceHeight / faceWidth
        } else {
            faceAspectRatio = 0
        }
        
        let eyeToFaceRatio: Double
        if faceWidth > 0 {
            eyeToFaceRatio = eyeDistance / faceWidth
        } else {
            eyeToFaceRatio = 0
        }
        
        let noseToFaceRatio: Double
        if faceWidth > 0 {
            noseToFaceRatio = noseWidth / faceWidth
        } else {
            noseToFaceRatio = 0
        }
        
        let mouthToFaceRatio: Double
        if faceWidth > 0 {
            mouthToFaceRatio = mouthWidth / faceWidth
        } else {
            mouthToFaceRatio = 0
        }
        
        // Additional measurements for 7-class discrimination
        let cheekboneWidth = distance(safeLandmark(0), safeLandmark(16))
        
        let cheekToJawRatio: Double
        if jawWidth > 0 {
            cheekToJawRatio = cheekboneWidth / jawWidth
        } else {
            cheekToJawRatio = 0
        }
        
        let foreheadToJawRatio: Double
        if jawWidth > 0 {
            foreheadToJawRatio = foreheadWidth / jawWidth
        } else {
            foreheadToJawRatio = 0
        }
        
        // Jaw shape analysis
        let jawHeight = abs(Double(safeLandmark(8).y - safeLandmark(27).y))
        
        let foreheadToFaceRatio: Double
        if faceWidth > 0 {
            foreheadToFaceRatio = foreheadWidth / faceWidth
        } else {
            foreheadToFaceRatio = 0
        }
        
        let jawToFaceRatio: Double
        if faceWidth > 0 {
            jawToFaceRatio = jawWidth / faceWidth
        } else {
            jawToFaceRatio = 0
        }
        
        // Compile exactly 25 features to match Python model
        let features = [
            faceWidth, faceHeight, widthHeightRatio, jawWidth, jawCurvature,
            foreheadWidth, eyeDistance, noseWidth, noseLength, mouthWidth,
            centroidX, centroidY, meanDistance, stdDistance, jawToForeheadRatio,
            faceAspectRatio, eyeToFaceRatio, noseToFaceRatio, mouthToFaceRatio,
            cheekboneWidth, cheekToJawRatio, foreheadToJawRatio, jawHeight,
            foreheadToFaceRatio, jawToFaceRatio
        ]
        
        return features
    }
    
    private func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count - 1)
        return sqrt(variance)
    }
    
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> Double {
        let dx = Double(p1.x - p2.x)
        let dy = Double(p1.y - p2.y)
        return sqrt(dx * dx + dy * dy)
    }
    
    private func extractClassPrediction(from probabilities: MLMultiArray) -> (String, Double) {
        var maxProbability: Double = 0.0
        var predictedClassIndex = 0
        
        // Find the class with highest probability
        for i in 0..<min(probabilities.count, faceShapeClasses.count) {
            let probability = probabilities[i].doubleValue
            if probability > maxProbability {
                maxProbability = probability
                predictedClassIndex = i
            }
        }
        
        let predictedClass = predictedClassIndex < faceShapeClasses.count ? faceShapeClasses[predictedClassIndex] : "Unknown"
        return (predictedClass, maxProbability)
    }
    
    private func extractLandmarks(from image: UIImage, completion: @escaping ([CGPoint]?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let request = VNDetectFaceLandmarksRequest { request, error in
            guard error == nil,
                  let results = request.results as? [VNFaceObservation],
                  let face = results.first,
                  let landmarks = face.landmarks else {
                print("❌ Could not detect face landmarks")
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
                print("❌ Error performing landmark detection: \(error)")
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
