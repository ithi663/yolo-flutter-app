import Foundation
import UIKit
import Vision
import CoreML

/// Specific error types for YOLO predictor operations
public enum YOLOPredictorError: Error, LocalizedError {
  case modelFileNotFound(String)
  case modelDescriptionUnavailable
  case modelMetadataUnavailable
  case invalidMetadata(String)
  case noClassLabelsFound(String)
  case invalidModelInputSize
  case visionModelCreationFailed(Error)
  case noDefaultModelsAvailable
  case allModelsFailedToLoad([String])
  case unknownError(Error)
  
  public var errorDescription: String? {
	switch self {
	case .modelFileNotFound(let path):
	  return "Model file does not exist at path: \(path)"
	case .modelDescriptionUnavailable:
	  return "Model description is not available"
	case .modelMetadataUnavailable:
	  return "Model metadata is not available"
	case .invalidMetadata(let message):
	  return "Invalid model metadata: \(message)"
	case .noClassLabelsFound(let availableKeys):
	  return "No valid class labels found in model metadata. Available keys: \(availableKeys)"
	case .invalidModelInputSize:
	  return "Could not determine valid model input size"
	case .visionModelCreationFailed(let error):
	  return "Failed to create Vision CoreML model: \(error.localizedDescription)"
	case .noDefaultModelsAvailable:
	  return "No default models found in app bundle. Please add YOLO models to the 'models' directory or bundle root."
	case .allModelsFailedToLoad(let attemptedModels):
	  return "All model loading attempts failed. Attempted models: \(attemptedModels.joined(separator: ", "))"
	case .unknownError(let error):
	  return "Unknown error occurred: \(error.localizedDescription)"
	}
  }
}

/// Base class for all YOLO model predictors, handling common model loading and inference logic.
///
/// The BasePredictor serves as the foundation for all task-specific YOLO model predictors.
/// It manages CoreML model loading, initialization, and common inference operations.
/// Specialized predictors (for detection, segmentation, etc.) inherit from this class
/// and override the prediction-specific methods to handle task-specific processing.
///
/// - Note: This class is marked as `@unchecked Sendable` to support concurrent operations.
/// - Important: Task-specific implementations must override the `processObservations` and
///   `predictOnImage` methods to provide proper functionality.
public class YOLOPBasePredictor: Predictor, @unchecked Sendable {
  /// Flag indicating if the model has been successfully loaded and is ready for inference.
  private(set) var isModelLoaded: Bool = false

  /// The Vision CoreML model used for inference operations.
  var detector: VNCoreMLModel!

  /// The Vision request that processes images using the CoreML model.
  var visionRequest: VNCoreMLRequest?

  /// The class labels used by the model for categorizing detections.
  public var labels = [String]()

  /// The current pixel buffer being processed (used for camera frame processing).
  var currentBuffer: CVPixelBuffer?

  /// The current listener to receive prediction results.
  weak var currentOnResultsListener: ResultsListener?

  /// The current listener to receive inference timing information.
  weak var currentOnInferenceTimeListener: InferenceTimeListener?

  /// The size of the input image or camera frame.
  var inputSize: CGSize!

  /// The required input dimensions for the model (width and height in pixels).
  var modelInputSize: (width: Int, height: Int) = (0, 0)

  /// Timestamp for the start of inference (used for performance measurement).
  var t0 = 0.0  // inference start

  /// Duration of a single inference operation.
  var t1 = 0.0  // inference dt

  /// Smoothed inference duration (averaged over recent operations).
  var t2 = 0.0  // inference dt smoothed

  /// Timestamp for FPS calculation start (used for performance measurement).
  var t3 = CACurrentMediaTime()  // FPS start

  /// Smoothed frames per second measurement (averaged over recent frames).
  var t4 = 0.0  // FPS dt smoothed

  /// Flag indicating whether the predictor is currently processing an update.
  public var isUpdating: Bool = false

  /// Required initializer for creating predictor instances.
  ///
  /// This empty initializer is required for the factory pattern used in the `create` method.
  /// Subclasses may override this to perform additional initialization.
  required init() {
	// Intentionally left empty
  }

  /// Public method to get information about available default models.
  ///
  /// This method can be used to check what default models are available before
  /// attempting to create a predictor.
  ///
  /// - Returns: An array of URLs for available default models.
  public static func getAvailableDefaultModels() -> [URL] {
	return findDefaultModels()
  }

  /// Prints information about the expected model directory structure and available models.
  ///
  /// This method helps developers understand where to place their YOLO models
  /// and shows what models are currently available.
  public static func printModelInfo() {
	print("=== YOLO Model Information ===")
	print("Expected model locations (in order of preference):")
	print("1. Plugin bundle Assets/models directory: ios/Assets/models/")
	print("2. Plugin bundle models directory: ios/models/")
	print("3. Plugin bundle Assets directory: ios/Assets/")
	print("4. Main app bundle (fallback): YourApp.app/")
	print("")
	print("For Flutter plugin development (Melos compatible):")
	print("- iOS: Place models in ios/Assets/models/ directory")
	print("- Android: Place models in android/src/main/assets/models/")
	print("- Configure podspec with: s.resources = ['Assets/**/*']")
	print("- For Melos monorepos: Ensure models are in the plugin root ios/Assets/")
	print("")
	print("Supported model names (in order of preference):")
	print("- yolo11n, yolo11n-seg, yolo11n_int8")
	print("- yolov8n, yolov8s, yolov8m, yolov8l, yolov8x")
	print("- yolov5n, yolov5s, yolov5m, yolov5l, yolov5x")
	print("- yolo, model, default")
	print("")
	print("Supported extensions: .mlpackage (preferred), .mlmodelc, .mlmodel")
	print("")
	
	// Debug bundle information
	printBundleDebugInfo()
	
	let availableModels = getAvailableDefaultModels()
	if availableModels.isEmpty {
	  print("❌ No default models found!")
	  print("Troubleshooting:")
	  print("1. Check if models exist in ios/Assets/models/ directory")
	  print("2. Verify podspec resource_bundles configuration")
	  print("3. Clean and rebuild the iOS project")
	  print("4. Check Xcode project for bundle resources")
	} else {
	  print("✅ Available default models:")
	  for (index, url) in availableModels.enumerated() {
		let bundleType = url.path.contains(Bundle(for: YOLOPBasePredictor.self).bundlePath) ? "Plugin" : "Main App"
		print("\(index + 1). \(url.lastPathComponent) (\(bundleType) Bundle)")
		print("   Path: \(url.path)")
	  }
	}
	print("==============================")
  }
  
  /// Debug helper to print bundle information
  private static func printBundleDebugInfo() {
	print("\n🔍 Bundle Debug Information:")
	let pluginBundle = Bundle(for: YOLOPBasePredictor.self)
	
	print("Plugin bundle path: \(pluginBundle.bundlePath)")
	print("Plugin bundle identifier: \(pluginBundle.bundleIdentifier ?? "unknown")")
	
	// Check resource bundles first
	if let resourceBundlePath = pluginBundle.path(forResource: "ultralytics_yolo_models", ofType: "bundle"),
	   let resourceBundle = Bundle(path: resourceBundlePath) {
	  print("✅ Found resource bundle: ultralytics_yolo_models")
	  print("   Bundle path: \(resourceBundlePath)")
	  
	  do {
		let contents = try FileManager.default.contentsOfDirectory(atPath: resourceBundlePath)
		let modelFiles = contents.filter { file in
		  file.hasSuffix(".mlpackage") || file.hasSuffix(".mlmodelc") || file.hasSuffix(".mlmodel")
		}
		
		if !modelFiles.isEmpty {
		  print("  Model files found in resource bundle:")
		  for file in modelFiles {
			print("    - \(file)")
		  }
		} else {
		  print("  No model files in resource bundle")
		  print("  Contents: \(contents.joined(separator: ", "))")
		}
	  } catch {
		print("  Error reading resource bundle: \(error)")
	  }
	} else {
	  print("❌ Resource bundle 'ultralytics_yolo_models' not found")
	}
	
	// Also check direct plugin bundle resources (fallback)
	let searchPaths = ["Assets/models", "models", "Assets", nil]
	
	for searchPath in searchPaths {
	  let pathDescription = searchPath ?? "root"
	  
	  if let searchURL = (searchPath != nil) ? 
		pluginBundle.url(forResource: searchPath!, withExtension: nil) :
		URL(fileURLWithPath: pluginBundle.bundlePath) {
		
		print("✅ Found directory: \(pathDescription) at \(searchURL.path)")
		
		// List contents
		do {
		  let contents = try FileManager.default.contentsOfDirectory(atPath: searchURL.path)
		  let modelFiles = contents.filter { file in
			file.hasSuffix(".mlpackage") || file.hasSuffix(".mlmodelc") || file.hasSuffix(".mlmodel")
		  }
		  
		  if !modelFiles.isEmpty {
			print("  Model files found:")
			for file in modelFiles {
			  print("    - \(file)")
			}
		  } else {
			print("  No model files in \(pathDescription)")
			if contents.count <= 5 {
			  print("  Contents: \(contents.joined(separator: ", "))")
			} else {
			  print("  \(contents.count) total files/directories")
			}
		  }
		} catch {
		  print("  Error reading directory: \(error)")
		}
	  } else {
		print("❌ Directory not found: \(pathDescription)")
	  }
	}
	
	print("")
  }

  /// Finds available default models in the plugin bundles.
  ///
  /// This method searches for pre-bundled YOLO models in the following locations:
  /// 1. Plugin resource bundle "ultralytics_yolo_models"
  /// 2. Plugin bundle's main bundle  
  /// 3. Main app bundle as fallback
  ///
  /// - Returns: An array of URLs for available default models, sorted by preference.
  private static func findDefaultModels() -> [URL] {
	var modelURLs: [URL] = []
	
	// Get the plugin bundle first (this class is part of the plugin)
	let pluginBundle = Bundle(for: YOLOPBasePredictor.self)
	
	// Common YOLO model names to search for
	let modelNames = [
	  "yolo11n", "yolo11s", "yolo11m", "yolo11l", "yolo11x",
	  "yolo11n-seg", "yolo11s-seg", "yolo11m-seg", "yolo11l-seg", "yolo11x-seg",
	  "yolo11n_int8", "yolo11s_int8", "yolo11m_int8", "yolo11l_int8", "yolo11x_int8",
	  "yolov8n", "yolov8s", "yolov8m", "yolov8l", "yolov8x",
	  "yolov5n", "yolov5s", "yolov5m", "yolov5l", "yolov5x",
	  "yolo", "model", "default"
	]
	
	let extensions = ["mlmodelc", "mlmodel", "mlpackage"]
	
	print("Searching for models in plugin bundle: \(pluginBundle.bundlePath)")
	
	// 1. Search in resource bundle first (most reliable)
	if let resourceBundlePath = pluginBundle.path(forResource: "ultralytics_yolo_models", ofType: "bundle"),
	   let resourceBundle = Bundle(path: resourceBundlePath) {
	  print("Found resource bundle: ultralytics_yolo_models")
	  
	  for modelName in modelNames {
		for ext in extensions {
		  if let url = resourceBundle.url(forResource: modelName, withExtension: ext) {
			modelURLs.append(url)
			print("Found model in resource bundle: \(url.lastPathComponent)")
		  }
		}
	  }
	} else {
	  print("Resource bundle 'ultralytics_yolo_models' not found, checking direct resources")
	}
	
	// 2. Search in plugin bundle with direct resources (fallback)
	// Search in Assets/models subdirectory first (primary location)
	for modelName in modelNames {
	  for ext in extensions {
		if let url = pluginBundle.url(forResource: modelName, withExtension: ext, subdirectory: "Assets/models") {
		  modelURLs.append(url)
		  print("Found model in plugin bundle (Assets/models/): \(url.lastPathComponent)")
		}
	  }
	}
	
	// Search in models subdirectory (alternative location)
	for modelName in modelNames {
	  for ext in extensions {
		if let url = pluginBundle.url(forResource: modelName, withExtension: ext, subdirectory: "models") {
		  modelURLs.append(url)
		  print("Found model in plugin bundle (models/): \(url.lastPathComponent)")
		}
	  }
	}
	
	// 3. Search in plugin main bundle (fallback)
	let searchDirectories = ["models", "Assets", nil] // nil means bundle root
	
	for directory in searchDirectories {
	  for modelName in modelNames {
		for ext in extensions {
		  if let url = pluginBundle.url(forResource: modelName, withExtension: ext, subdirectory: directory) {
			modelURLs.append(url)
			let location = directory ?? "root"
			print("Found model in plugin bundle (\(location)): \(url.lastPathComponent)")
		  }
		}
	  }
	}
	
	// 4. Search in main app bundle for preloaded models (with .data extension to avoid CoreML compilation)
	let mainBundle = Bundle.main
	print("Searching main app bundle for preloaded models...")
	
	// First check for models stored as .data files to avoid CoreML auto-compilation
	for modelName in modelNames {
	  if let dataURL = mainBundle.url(forResource: "\(modelName).mlpackage", withExtension: "data", subdirectory: "Resources/models") {
		// Create a temporary URL with the correct .mlpackage extension
		let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		let tempModelPath = documentsPath.appendingPathComponent("temp_models")
		let correctedURL = tempModelPath.appendingPathComponent("\(modelName).mlpackage")
		
		do {
		  // Create temp directory if needed
		  try FileManager.default.createDirectory(at: tempModelPath, withIntermediateDirectories: true, attributes: nil)
		  
		  // Copy and rename the .data file to .mlpackage
		  if !FileManager.default.fileExists(atPath: correctedURL.path) {
			try FileManager.default.copyItem(at: dataURL, to: correctedURL)
		  }
		  
		  modelURLs.append(correctedURL)
		  print("Found preloaded model in main app bundle: \(modelName).mlpackage (converted from .data)")
		} catch {
		  print("Error processing preloaded model \(modelName): \(error)")
		}
	  }
	}
	
	// Fallback to regular search in main app bundle
	for directory in searchDirectories {
	  for modelName in modelNames {
		for ext in extensions {
		  if let url = mainBundle.url(forResource: modelName, withExtension: ext, subdirectory: directory) {
			modelURLs.append(url)
			let location = directory ?? "root"
			print("Found model in main app bundle (\(location)): \(url.lastPathComponent)")
		  }
		}
	  }
	}
	
	// Remove duplicates while preserving order
	var uniqueURLs: [URL] = []
	var seenPaths: Set<String> = []
	
	for url in modelURLs {
	  if !seenPaths.contains(url.path) {
		uniqueURLs.append(url)
		seenPaths.insert(url.path)
	  }
	}
	
	print("Total unique models found: \(uniqueURLs.count)")
	return uniqueURLs
  }

  /// Attempts to load a model from the given URL with fallback support.
  ///
  /// This method tries to load the specified model URL first, and if that fails,
  /// it attempts to load from available default models in the bundle.
  ///
  /// - Parameters:
  ///   - preferredURL: The preferred model URL to try first (can be nil).
  ///   - isRealTime: Flag indicating if the predictor will be used for real-time processing.
  ///   - completion: Callback that receives the initialized predictor or an error.
  private static func loadModelWithFallback(
	preferredURL: URL?,
	isRealTime: Bool,
	completion: @escaping (Result<YOLOPBasePredictor, Error>) -> Void
  ) {
	let modelURLsToTry: [URL]
	
	if let preferredURL = preferredURL {
	  // Try preferred URL first, then default models as fallback
	  modelURLsToTry = [preferredURL] + findDefaultModels()
	} else {
	  // Only try default models
	  modelURLsToTry = findDefaultModels()
	}
	
	guard !modelURLsToTry.isEmpty else {
	  let error = YOLOPredictorError.noDefaultModelsAvailable
	  print("No models available to try loading")
	  DispatchQueue.main.async {
		completion(.failure(error))
	  }
	  return
	}
	
	// Try loading models in order until one succeeds
	tryLoadingModels(urls: modelURLsToTry, isRealTime: isRealTime, completion: completion)
  }

  /// Recursively tries loading models from a list of URLs until one succeeds.
  ///
  /// - Parameters:
  ///   - urls: Array of URLs to try loading.
  ///   - isRealTime: Flag indicating if the predictor will be used for real-time processing.
  ///   - completion: Callback that receives the initialized predictor or an error.
  private static func tryLoadingModels(
	urls: [URL],
	isRealTime: Bool,
	completion: @escaping (Result<YOLOPBasePredictor, Error>) -> Void
  ) {
	tryLoadingModelsRecursive(urls: urls, isRealTime: isRealTime, failedModels: [], completion: completion)
  }

  /// Internal recursive method that tracks failed models.
  private static func tryLoadingModelsRecursive(
	urls: [URL],
	isRealTime: Bool,
	failedModels: [String],
	completion: @escaping (Result<YOLOPBasePredictor, Error>) -> Void
  ) {
	guard let currentURL = urls.first else {
	  // No more URLs to try
	  let error = YOLOPredictorError.allModelsFailedToLoad(failedModels)
	  DispatchQueue.main.async {
		completion(.failure(error))
	  }
	  return
	}
	
	let remainingURLs = Array(urls.dropFirst())
	let currentModelName = currentURL.lastPathComponent
	
	print("Attempting to load model: \(currentModelName)")
	
	// Try loading the current URL
	loadSingleModel(
	  unwrappedModelURL: currentURL,
	  isRealTime: isRealTime
	) { result in
	  switch result {
	  case .success(let predictor):
		print("Successfully loaded model: \(currentModelName)")
		completion(.success(predictor))
	  case .failure(let error):
		print("Failed to load model \(currentModelName): \(error.localizedDescription)")
		
		let updatedFailedModels = failedModels + [currentModelName]
		
		if !remainingURLs.isEmpty {
		  // Try the next model
		  tryLoadingModelsRecursive(
			urls: remainingURLs,
			isRealTime: isRealTime,
			failedModels: updatedFailedModels,
			completion: completion
		  )
		} else {
		  // No more models to try, return the aggregated error
		  let error = YOLOPredictorError.allModelsFailedToLoad(updatedFailedModels)
		  completion(.failure(error))
		}
	  }
	}
  }

  /// Performs cleanup when the predictor is deallocated.
  ///
  /// Cancels any pending vision requests and releases references to avoid memory leaks.
  deinit {
	visionRequest?.cancel()
	visionRequest = nil
  }

  /// Factory method to asynchronously create and initialize a predictor with the specified model.
  ///
  /// This method loads the CoreML model in a background thread and sets up the prediction
  /// infrastructure. The completion handler is called on the main thread with either a
  /// successfully initialized predictor or an error.
  ///
  /// - Parameters:
  ///   - unwrappedModelURL: The URL of the CoreML model file to load. If nil, will attempt to use default bundled model.
  ///   - isRealTime: Flag indicating if the predictor will be used for real-time processing (camera feed).
  ///   - completion: Callback that receives the initialized predictor or an error.
  /// - Note: Model loading happens on a background thread to avoid blocking the main thread.
  public static func createModel(
	unwrappedModelURL: URL? = nil,
	isRealTime: Bool = false,
	completion: @escaping (Result<YOLOPBasePredictor, Error>) -> Void
  ) {
	// Use the new fallback loading mechanism
	loadModelWithFallback(
	  preferredURL: unwrappedModelURL,
	  isRealTime: isRealTime,
	  completion: completion
	)
  }

  /// Loads a single model from the specified URL without fallback logic.
  ///
  /// This is the core model loading method that handles the actual CoreML model
  /// loading and initialization for a single URL.
  ///
  /// - Parameters:
  ///   - unwrappedModelURL: The URL of the CoreML model file to load.
  ///   - isRealTime: Flag indicating if the predictor will be used for real-time processing.
  ///   - completion: Callback that receives the initialized predictor or an error.
  private static func loadSingleModel(
	unwrappedModelURL: URL,
	isRealTime: Bool,
	completion: @escaping (Result<YOLOPBasePredictor, Error>) -> Void
  ) {
	// Create an instance (synchronously, cheap)
	let predictor = Self.init()

	// Kick off the expensive loading on a background thread
	DispatchQueue.global(qos: .userInitiated).async {
	  do {
		// Check if model file exists first
		guard FileManager.default.fileExists(atPath: unwrappedModelURL.path) else {
		  throw YOLOPredictorError.modelFileNotFound(unwrappedModelURL.path)
		}

		// (1) Load the MLModel
		let ext = unwrappedModelURL.pathExtension.lowercased()
		let isCompiled = (ext == "mlmodelc")
		let config = MLModelConfiguration()
		if #available(iOS 16.0, *) {
		  config.setValue(1, forKey: "experimentalMLE5EngineUsage")
		}

		let mlModel: MLModel
		if isCompiled {
		  mlModel = try MLModel(contentsOf: unwrappedModelURL, configuration: config)
		} else {
		  let compiledUrl = try MLModel.compileModel(at: unwrappedModelURL)
		  mlModel = try MLModel(contentsOf: compiledUrl, configuration: config)
		}

		// Safely check for model description and metadata
		guard let modelDescription = mlModel.modelDescription as MLModelDescription? else {
		  throw YOLOPredictorError.modelDescriptionUnavailable
		}

		guard let metadata = modelDescription.metadata as [MLModelMetadataKey: Any]? else {
		  throw YOLOPredictorError.modelMetadataUnavailable
		}

		guard let userDefined = metadata[MLModelMetadataKey.creatorDefinedKey] as? [String: String] else {
		  throw YOLOPredictorError.invalidMetadata("Creator-defined metadata is missing or invalid. Please ensure the model contains proper class labels.")
		}

		// (2) Extract class labels with better error handling
		var labelsFound = false
		if let labelsData = userDefined["classes"], !labelsData.isEmpty {
		  predictor.labels = labelsData.components(separatedBy: ",").compactMap { label in
			let trimmed = label.trimmingCharacters(in: .whitespaces)
			return trimmed.isEmpty ? nil : trimmed
		  }
		  labelsFound = !predictor.labels.isEmpty
		} else if let labelsData = userDefined["names"], !labelsData.isEmpty {
		  // Parse JSON/dictionary-ish format with better error handling
		  let cleanedInput =
			labelsData
			.replacingOccurrences(of: "{", with: "")
			.replacingOccurrences(of: "}", with: "")
			.replacingOccurrences(of: " ", with: "")
		  let keyValuePairs = cleanedInput.components(separatedBy: ",")
		  for pair in keyValuePairs {
			let components = pair.components(separatedBy: ":")
			if components.count >= 2 {
			  let extractedString = components[1].trimmingCharacters(in: .whitespaces)
			  let cleanedString = extractedString.replacingOccurrences(of: "'", with: "")
			  if !cleanedString.isEmpty {
			  predictor.labels.append(cleanedString)
			}
		  }
		  }
		  labelsFound = !predictor.labels.isEmpty
		}
		
		if !labelsFound || predictor.labels.isEmpty {
		  throw YOLOPredictorError.noClassLabelsFound(userDefined.keys.joined(separator: ", "))
		}

		// (3) Store model input size with validation
		predictor.modelInputSize = predictor.getModelInputSize(for: mlModel)
		if predictor.modelInputSize.width == 0 || predictor.modelInputSize.height == 0 {
		  throw YOLOPredictorError.invalidModelInputSize
		}

		// (4) Create VNCoreMLModel, VNCoreMLRequest, etc.
		do {
		predictor.detector = try VNCoreMLModel(for: mlModel)
		} catch {
		  throw YOLOPredictorError.visionModelCreationFailed(error)
		}
		
		// Safely set feature provider if available
		if let thresholdProvider = ThresholdProvider() as? MLFeatureProvider {
		  predictor.detector.featureProvider = thresholdProvider
		}
		
		predictor.visionRequest = {
		  let request = VNCoreMLRequest(
			model: predictor.detector,
			completionHandler: {
			  [weak predictor] request, error in
			  guard let predictor = predictor else {
				// The predictor was deallocated — do nothing
				return
			  }
			  if isRealTime {
				predictor.processObservations(for: request, error: error)
			  }
			})
		  request.imageCropAndScaleOption = .scaleFill
		  return request
		}()

		// Once done, mark it loaded
		predictor.isModelLoaded = true

		// Finally, call the completion on the main thread
		DispatchQueue.main.async {
		  completion(.success(predictor))
		}
	  } catch let error as YOLOPredictorError {
		// Handle our specific YOLO predictor errors
		print("Model loading failed with YOLO error: \(error.localizedDescription)")
		DispatchQueue.main.async {
		  completion(.failure(error))
		}
	  } catch {
		// Handle any other unexpected errors
		let wrappedError = YOLOPredictorError.unknownError(error)
		print("Model loading failed with unknown error: \(error.localizedDescription)")
		DispatchQueue.main.async {
		  completion(.failure(wrappedError))
		}
	  }
	}
  }

  /// Processes a camera frame buffer and delivers results via callbacks.
  ///
  /// This method takes a camera sample buffer, performs inference using the Vision framework,
  /// and notifies listeners with the results and performance metrics. It's designed to be
  /// called repeatedly with frames from a camera feed.
  ///
  /// - Parameters:
  ///   - sampleBuffer: The camera frame buffer to process.
  ///   - onResultsListener: Optional listener to receive prediction results.
  ///   - onInferenceTime: Optional listener to receive performance metrics.
  func predict(
	sampleBuffer: CMSampleBuffer, onResultsListener: ResultsListener?,
	onInferenceTime: InferenceTimeListener?
  ) {
	// Check if model is loaded before attempting prediction
	guard isModelLoaded else {
	  print("Warning: Attempted to predict with unloaded model")
	  return
	}
	
	guard let visionRequest = visionRequest else {
	  print("Warning: Vision request is not available")
	  return
	}
	
	if currentBuffer == nil, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
	  currentBuffer = pixelBuffer
	  inputSize = CGSize(
		width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
	  currentOnResultsListener = onResultsListener
	  currentOnInferenceTimeListener = onInferenceTime
	  //            currentOnFpsRateListener = onFpsRate

	  /// - Tag: MappingOrientation
	  // The frame is always oriented based on the camera sensor,
	  // so in most cases Vision needs to rotate it for the model to work as expected.
	  let imageOrientation: CGImagePropertyOrientation = .up

	  // Invoke a VNRequestHandler with that image
	  let handler = VNImageRequestHandler(
		cvPixelBuffer: pixelBuffer, orientation: imageOrientation, options: [:])
	  t0 = CACurrentMediaTime()  // inference start
	  do {
		try handler.perform([visionRequest])
	  } catch {
		print("Vision request failed with error: \(error.localizedDescription)")
		// Notify listeners about the error
		currentOnResultsListener = nil
		currentOnInferenceTimeListener = nil
	  }
	  t1 = CACurrentMediaTime() - t0  // inference dt

	  currentBuffer = nil
	}
  }

  /// The confidence threshold for filtering detection results (default: 0.25).
  ///
  /// Only detections with confidence scores above this threshold will be included in results.
  var confidenceThreshold = 0.25

  /// Sets the confidence threshold for filtering results.
  ///
  /// - Parameter confidence: The new confidence threshold value (0.0 to 1.0).
  func setConfidenceThreshold(confidence: Double) {
	confidenceThreshold = confidence
  }

  /// The IoU (Intersection over Union) threshold for non-maximum suppression (default: 0.4).
  ///
  /// Used to filter overlapping detections during non-maximum suppression.
  var iouThreshold = 0.4

  /// Sets the IoU threshold for non-maximum suppression.
  ///
  /// - Parameter iou: The new IoU threshold value (0.0 to 1.0).
  func setIouThreshold(iou: Double) {
	iouThreshold = iou
  }

  /// The maximum number of detections to return in results (default: 30).
  ///
  /// Limits the number of detection items in the final results to prevent overwhelming processing.
  var numItemsThreshold = 30

  /// Sets the maximum number of detection items to include in results.
  ///
  /// - Parameter numItems: The maximum number of items to include.
  func setNumItemsThreshold(numItems: Int) {
	numItemsThreshold = numItems
  }

  /// Processes Vision framework observations from model inference.
  ///
  /// This method is called when Vision completes a request with the model's outputs.
  /// Subclasses must override this method to implement task-specific processing of the
  /// model's output features (e.g., parsing detection boxes, segmentation masks, etc.).
  ///
  /// - Parameters:
  ///   - request: The completed Vision request containing model outputs.
  ///   - error: Any error that occurred during the Vision request.
  func processObservations(for request: VNRequest, error: Error?) {
	// Base implementation is empty - must be overridden by subclasses
  }

  /// Processes a static image and returns results synchronously.
  ///
  /// This method performs model inference on a static image and returns the results.
  /// Subclasses must override this method to implement task-specific processing.
  ///
  /// - Parameter image: The CIImage to process.
  /// - Returns: A YOLOResult containing the prediction outputs.
  func predictOnImage(image: CIImage) -> YOLOResult {
	// Base implementation returns an empty result - must be overridden by subclasses
	return YOLOResult(orig_shape: .zero, boxes: [], speed: 0, names: [])
  }

  /// Extracts the required input dimensions from the model description.
  ///
  /// This utility method determines the expected input size for the CoreML model
  /// by examining its input description, which is essential for properly sizing
  /// and formatting images before inference.
  ///
  /// - Parameter model: The CoreML model to analyze.
  /// - Returns: A tuple containing the width and height in pixels required by the model.
  func getModelInputSize(for model: MLModel) -> (width: Int, height: Int) {
	guard let inputDescriptions = model.modelDescription.inputDescriptionsByName as? [String: MLFeatureDescription],
		  !inputDescriptions.isEmpty else {
	  print("Cannot find input descriptions in model")
	  return (0, 0)
	}
	
	// Try to find the first valid input description
	for (name, inputDescription) in inputDescriptions {
	  print("Checking input: \(name)")

	if let multiArrayConstraint = inputDescription.multiArrayConstraint {
	  let shape = multiArrayConstraint.shape
		print("MultiArray shape: \(shape)")
	  if shape.count >= 2 {
		  // Common formats: [N, C, H, W] or [N, H, W, C] or [H, W, C]
		  if shape.count == 4 {
			// Format: [N, C, H, W] or [N, H, W, C]
			let height = shape[2].intValue
			let width = shape[3].intValue
			if height > 0 && width > 0 {
			  return (width: width, height: height)
			}
		  } else if shape.count == 3 {
			// Format: [H, W, C] or [C, H, W]
			let height = shape[1].intValue
			let width = shape[2].intValue
			if height > 0 && width > 0 {
			  return (width: width, height: height)
			}
		  } else if shape.count >= 2 {
			// Fallback: assume last two dimensions are height and width
			let height = shape[shape.count - 2].intValue
			let width = shape[shape.count - 1].intValue
			if height > 0 && width > 0 {
		return (width: width, height: height)
			}
		  }
	  }
	}

	if let imageConstraint = inputDescription.imageConstraint {
	  let width = Int(imageConstraint.pixelsWide)
	  let height = Int(imageConstraint.pixelsHigh)
		print("Image constraint size: \(width)x\(height)")
		if width > 0 && height > 0 {
	  return (width: width, height: height)
		}
	  }
	}

	print("Could not determine valid input size from any input description")
	return (0, 0)
  }
}


