// Ultralytics 🚀 AGPL-3.0 License - https://ultralytics.com/license

import Flutter
import UIKit

@MainActor
public class YOLOPlugin: NSObject, FlutterPlugin {
  // Dictionary to store channels for each instance
  private static var instanceChannels: [String: FlutterMethodChannel] = [:]
  // Store the registrar for creating new channels
  private static var pluginRegistrar: FlutterPluginRegistrar?
  
  // Model cache for reusing YOLO instances
  private static var modelCache: [String: YOLO] = [:]
  private static let cacheQueue = DispatchQueue(label: "yolo.model.cache", attributes: .concurrent)

  public static func register(with registrar: FlutterPluginRegistrar) {
    // Store the registrar for later use
    pluginRegistrar = registrar
    // 1) Register the platform view
    let factory = SwiftYOLOPlatformViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "com.ultralytics.yolo/YOLOPlatformView")

    // 2) Register the default method channel for backward compatibility
    let defaultChannel = FlutterMethodChannel(
      name: "yolo_single_image_channel",
      binaryMessenger: registrar.messenger()
    )
    let instance = YOLOPlugin()
    registrar.addMethodCallDelegate(instance, channel: defaultChannel)
  }

  private func registerInstanceChannel(instanceId: String, messenger: FlutterBinaryMessenger) {
    let channelName = "yolo_single_image_channel_\(instanceId)"
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    let instance = YOLOPlugin()
    // Store the channel for later use
    YOLOPlugin.instanceChannels[instanceId] = channel
    // Register this instance as the method call delegate
    if let registrar = YOLOPlugin.pluginRegistrar {
      registrar.addMethodCallDelegate(instance, channel: channel)
    }
  }

  private func checkModelExists(modelPath: String) -> [String: Any] {
    let fileManager = FileManager.default
    var resultMap: [String: Any] = [
      "exists": false,
      "path": modelPath,
      "location": "unknown",
    ]

    // 1. Check absolute paths first
    if modelPath.hasPrefix("/") {
      if fileManager.fileExists(atPath: modelPath) {
        resultMap["exists"] = true
        resultMap["location"] = "file_system"
        resultMap["absolutePath"] = modelPath
        return resultMap
      }
    }

    // 2. Use BasePredictor's model discovery (plugin bundle compatible)
    let availableModels = YOLOPBasePredictor.getAvailableDefaultModels()
    let modelFileName = modelPath.components(separatedBy: "/").last ?? modelPath
    
    // Try exact matches first
    for modelURL in availableModels {
      let modelName = modelURL.lastPathComponent
      if modelName == modelPath || modelName == modelFileName {
        resultMap["exists"] = true
        resultMap["location"] = "plugin_bundle_model"
        resultMap["absolutePath"] = modelURL.path
        return resultMap
      }
      
      // Try without extension
      let nameWithoutExt = modelURL.deletingPathExtension().lastPathComponent
      if nameWithoutExt == modelPath || nameWithoutExt == modelFileName {
        resultMap["exists"] = true
        resultMap["location"] = "plugin_bundle_model_no_ext"
        resultMap["absolutePath"] = modelURL.path
        return resultMap
      }
    }

    // 3. Fallback to original main bundle search for compatibility
    let fileName = modelPath.components(separatedBy: "/").last ?? modelPath
    
    // Check flutter assets
    if modelPath.contains("/") {
      let components = modelPath.components(separatedBy: "/")
      let directory = components.dropLast().joined(separator: "/")
      let assetPath = "flutter_assets/\(directory)"
      
      if let fullPath = Bundle.main.path(forResource: fileName, ofType: nil, inDirectory: assetPath) {
        resultMap["exists"] = true
        resultMap["location"] = "flutter_assets_directory"
        resultMap["absolutePath"] = fullPath
        return resultMap
      }
    }

    if let fullPath = Bundle.main.path(forResource: fileName, ofType: nil, inDirectory: "flutter_assets") {
      resultMap["exists"] = true
      resultMap["location"] = "flutter_assets_root"
      resultMap["absolutePath"] = fullPath
      return resultMap
    }

    // Check main bundle resources
    let fileComponents = fileName.components(separatedBy: ".")
    if fileComponents.count > 1 {
      let name = fileComponents.dropLast().joined(separator: ".")
      let ext = fileComponents.last ?? ""

      if let fullPath = Bundle.main.path(forResource: name, ofType: ext) {
        resultMap["exists"] = true
        resultMap["location"] = "main_bundle_resource"
        resultMap["absolutePath"] = fullPath
        return resultMap
      }
    }

    // Check specific extensions
    if let compiledURL = Bundle.main.url(forResource: fileName, withExtension: "mlmodelc") {
      resultMap["exists"] = true
      resultMap["location"] = "main_bundle_compiled"
      resultMap["absolutePath"] = compiledURL.path
      return resultMap
    }

    if let packageURL = Bundle.main.url(forResource: fileName, withExtension: "mlpackage") {
      resultMap["exists"] = true
      resultMap["location"] = "main_bundle_package"
      resultMap["absolutePath"] = packageURL.path
      return resultMap
    }

    print("🔍 Model '\(modelPath)' not found in any location. Available models:")
    for (index, url) in availableModels.enumerated() {
      print("  \(index + 1). \(url.lastPathComponent) at \(url.path)")
    }

    return resultMap
  }
  
  // Helper function to get or create cached YOLO model
  private static func getOrCreateModel(modelPath: String, task: YOLOTask, completion: @escaping (Result<YOLO, Error>) -> Void) {
    let key = "\(modelPath)-\(task)"
    
    cacheQueue.async {
      if let cachedModel = modelCache[key] {
        DispatchQueue.main.async {
          completion(.success(cachedModel))
        }
        return
      }
      
      // Create new model
      YOLO(modelPath, task: task) { result in
        switch result {
        case .success(let yolo):
          cacheQueue.async(flags: .barrier) {
            modelCache[key] = yolo
          }
          DispatchQueue.main.async {
            completion(.success(yolo))
          }
        case .failure(let error):
          DispatchQueue.main.async {
            completion(.failure(error))
          }
        }
      }
    }
  }

  private func getStoragePaths() -> [String: String?] {
    let fileManager = FileManager.default
    let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
    let applicationSupportDirectory = fileManager.urls(
      for: .applicationSupportDirectory, in: .userDomainMask
    ).first

    return [
      "internal": applicationSupportDirectory?.path,
      "cache": cachesDirectory?.path,
      "documents": documentsDirectory?.path,
    ]
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    Task { @MainActor in
      switch call.method {
      case "createInstance":
        guard let args = call.arguments as? [String: Any],
          let instanceId = args["instanceId"] as? String
        else {
          result(
            FlutterError(
              code: "bad_args", message: "Invalid arguments for createInstance", details: nil)
          )
          return
        }

        // Create the instance in the manager
        YOLOInstanceManager.shared.createInstance(instanceId: instanceId)

        // Register a new channel for this instance
        if let registrar = YOLOPlugin.pluginRegistrar {
          registerInstanceChannel(instanceId: instanceId, messenger: registrar.messenger())
        }

        result(nil)

      case "loadModel":
        guard let args = call.arguments as? [String: Any],
          let modelPath = args["modelPath"] as? String,
          let taskString = args["task"] as? String
        else {
          result(
            FlutterError(code: "bad_args", message: "Invalid arguments for loadModel", details: nil)
          )
          return
        }

        let task = YOLOTask.fromString(taskString)
        let instanceId = args["instanceId"] as? String ?? "default"

        do {
          try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            YOLOInstanceManager.shared.loadModel(
              instanceId: instanceId,
              modelName: modelPath,
              task: task
            ) { modelResult in
              switch modelResult {
              case .success:
                continuation.resume()
              case .failure(let error):
                continuation.resume(throwing: error)
              }
            }
          }
          result(true)
        } catch {
          result(
            FlutterError(
              code: "MODEL_NOT_FOUND",
              message: error.localizedDescription,
              details: nil
            )
          )
        }

      case "predictSingleImage":
        guard let args = call.arguments as? [String: Any],
          let data = args["image"] as? FlutterStandardTypedData
        else {
          result(
            FlutterError(
              code: "bad_args", message: "Invalid arguments for predictSingleImage", details: nil)
          )
          return
        }

        let instanceId = args["instanceId"] as? String ?? "default"
        let confidenceThreshold = args["confidenceThreshold"] as? Double
        let iouThreshold = args["iouThreshold"] as? Double
        let generateAnnotatedImage = args["generateAnnotatedImage"] as? Bool ?? false

        if let resultDict = YOLOInstanceManager.shared.predict(
          instanceId: instanceId,
          imageData: data.data,
          confidenceThreshold: confidenceThreshold,
          iouThreshold: iouThreshold,
          generateAnnotatedImage: generateAnnotatedImage
        ) {
          result(resultDict)
        } else {
          result(
            FlutterError(
              code: "MODEL_NOT_LOADED",
              message: "Model has not been loaded. Call loadModel() first.",
              details: nil
            )
          )
        }

      case "disposeInstance":
        guard let args = call.arguments as? [String: Any],
          let instanceId = args["instanceId"] as? String
        else {
          result(
            FlutterError(
              code: "bad_args", message: "Invalid arguments for disposeInstance", details: nil)
          )
          return
        }

        YOLOInstanceManager.shared.removeInstance(instanceId: instanceId)

        // Remove the channel for this instance
        YOLOPlugin.instanceChannels.removeValue(forKey: instanceId)

        result(nil)

      case "checkModelExists":
        guard let args = call.arguments as? [String: Any],
          let modelPath = args["modelPath"] as? String
        else {
          result(
            FlutterError(
              code: "bad_args", message: "Invalid arguments for checkModelExists", details: nil)
          )
          return
        }

        let checkResult = checkModelExists(modelPath: modelPath)
        result(checkResult)

      case "getStoragePaths":
        let paths = getStoragePaths()
        result(paths)
        
      case "printModelInfo":
        YOLOPBasePredictor.printModelInfo()
        result(nil)
        
      case "getAvailableModels":
        let models = YOLOPBasePredictor.getAvailableDefaultModels()
        let modelPaths = models.map { $0.path }
        result(modelPaths)

      case "setModel":
        guard let args = call.arguments as? [String: Any],
          let viewId = args["viewId"] as? Int,
          let modelPath = args["modelPath"] as? String,
          let taskString = args["task"] as? String
        else {
          result(
            FlutterError(code: "bad_args", message: "Invalid arguments for setModel", details: nil)
          )
          return
        }

        let task = YOLOTask.fromString(taskString)

        // Get the YOLOView instance from the factory
        if let yoloView = SwiftYOLOPlatformViewFactory.getYOLOView(for: viewId) {
          yoloView.setModel(modelPathOrName: modelPath, task: task) { modelResult in
            switch modelResult {
            case .success:
              result(nil)  // Success
            case .failure(let error):
              result(
                FlutterError(
                  code: "MODEL_NOT_FOUND",
                  message: "Failed to load model: \(modelPath) - \(error.localizedDescription)",
                  details: nil
                )
              )
            }
          }
        } else {
          result(
            FlutterError(
              code: "VIEW_NOT_FOUND",
              message: "YOLOView with id \(viewId) not found",
              details: nil
            )
          )
        }

      case "detectInImage":
        guard let args = call.arguments as? [String: Any],
          let imageData = args["imageBytes"] as? FlutterStandardTypedData,
          let modelPath = args["modelPath"] as? String,
          let taskString = args["task"] as? String
        else {
          result(
            FlutterError(
              code: "bad_args", message: "Invalid arguments for detectInImage", details: nil)
          )
          return
        }

        let confidenceThreshold = args["confidenceThreshold"] as? Double ?? 0.25
        let iouThreshold = args["iouThreshold"] as? Double ?? 0.45
        let maxDetections = args["maxDetections"] as? Int ?? 100
        let generateAnnotatedImage = args["generateAnnotatedImage"] as? Bool ?? false
        let task = YOLOTask.fromString(taskString)

        // Convert image data to UIImage
        guard let uiImage = UIImage(data: imageData.data) else {
          result(
            FlutterError(
              code: "image_error", message: "Failed to decode image", details: nil)
          )
          return
        }

        performStaticImageDetection(
          image: uiImage,
          modelPath: modelPath,
          task: task,
          confidenceThreshold: confidenceThreshold,
          iouThreshold: iouThreshold,
          maxDetections: maxDetections,
          generateAnnotatedImage: generateAnnotatedImage,
          result: result
        )

      case "detectInImageFile":
        guard let args = call.arguments as? [String: Any],
          let imagePath = args["imagePath"] as? String,
          let modelPath = args["modelPath"] as? String,
          let taskString = args["task"] as? String
        else {
          result(
            FlutterError(
              code: "bad_args", message: "Invalid arguments for detectInImageFile", details: nil)
          )
          return
        }

        let confidenceThreshold = args["confidenceThreshold"] as? Double ?? 0.25
        let iouThreshold = args["iouThreshold"] as? Double ?? 0.45
        let maxDetections = args["maxDetections"] as? Int ?? 100
        let generateAnnotatedImage = args["generateAnnotatedImage"] as? Bool ?? false
        let task = YOLOTask.fromString(taskString)

        // Load image from file
        guard let uiImage = UIImage(contentsOfFile: imagePath) else {
          result(
            FlutterError(
              code: "image_error", 
              message: "Failed to load image from file: \(imagePath)", 
              details: nil
            )
          )
          return
        }

        performStaticImageDetection(
          image: uiImage,
          modelPath: modelPath,
          task: task,
          confidenceThreshold: confidenceThreshold,
          iouThreshold: iouThreshold,
          maxDetections: maxDetections,
          generateAnnotatedImage: generateAnnotatedImage,
          result: result
        )

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // Helper function to perform static image detection
  private func performStaticImageDetection(
    image: UIImage,
    modelPath: String,
    task: YOLOTask,
    confidenceThreshold: Double,
    iouThreshold: Double,
    maxDetections: Int,
    generateAnnotatedImage: Bool,
    result: @escaping FlutterResult
  ) {
    // Use cached model and run inference on background queue
    DispatchQueue.global(qos: .userInitiated).async {
      YOLOPlugin.getOrCreateModel(modelPath: modelPath, task: task) { yoloResult in
        switch yoloResult {
        case .success(let yolo):
          // Set the thresholds
          yolo.confidenceThreshold = confidenceThreshold
          yolo.iouThreshold = iouThreshold
          
          // Run inference using the YOLO callable function
          let inferenceResult = yolo(image)
        
        // Convert results to Flutter format
        var detections: [[String: Any]] = []
        let limitedResults = Array(inferenceResult.boxes.prefix(maxDetections))
        
        for (index, box) in limitedResults.enumerated() {
          var detection: [String: Any] = [
            "classIndex": box.index,
            "className": box.cls,
            "confidence": Double(box.conf),
            "boundingBox": [
              "left": Double(box.xywh.minX),
              "top": Double(box.xywh.minY),
              "right": Double(box.xywh.maxX),
              "bottom": Double(box.xywh.maxY)
            ],
            "normalizedBox": [
              "left": Double(box.xywhn.minX),
              "top": Double(box.xywhn.minY),
              "right": Double(box.xywhn.maxX),
              "bottom": Double(box.xywhn.maxY)
            ]
          ]
          
          // Add task-specific data
          switch task {
          case .segment:
            // Add mask data if available
            if let masks = inferenceResult.masks, index < masks.masks.count {
              let mask = masks.masks[index]
              // Convert mask to list of lists for Flutter
              let maskData = mask.map { row in
                row.map { Double($0) }
              }
              detection["mask"] = maskData
            }
          case .pose:
            // Add keypoints if available
            if index < inferenceResult.keypointsList.count {
              let keypoints = inferenceResult.keypointsList[index]
              // Convert to flat array format like in the stream data
              var keypointsFlat: [Double] = []
              for i in 0..<keypoints.xyn.count {
                keypointsFlat.append(Double(keypoints.xyn[i].x))
                keypointsFlat.append(Double(keypoints.xyn[i].y))
                if i < keypoints.conf.count {
                  keypointsFlat.append(Double(keypoints.conf[i]))
                } else {
                  keypointsFlat.append(0.0)  // Default confidence if missing
                }
              }
              detection["keypoints"] = keypointsFlat
            }
          default:
            break // Other tasks handled by base detection data
          }
          
          detections.append(detection)
        }
        
          DispatchQueue.main.async {
            result(detections)
          }
          
        case .failure(let error):
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "model_load_error", 
                message: "Failed to load YOLO model: \(error.localizedDescription)", 
                details: nil
              )
            )
          }
        }
      }
    }
  }
}
