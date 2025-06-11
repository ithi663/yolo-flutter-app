#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint yolo.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'ultralytics_yolo'
  s.version          = '0.0.4'
  s.summary          = 'Flutter plugin for YOLO (You Only Look Once) models'
  s.description      = <<-DESC
Flutter plugin for YOLO (You Only Look Once) models, supporting object detection, segmentation, classification, pose estimation and oriented bounding boxes (OBB) on both Android and iOS.
                       DESC
  s.homepage         = 'https://github.com/ultralytics/yolo-flutter-app'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Ultralytics' => 'info@ultralytics.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # Bundle only privacy manifest - models will be loaded from app assets
  s.resources = ['Resources/PrivacyInfo.xcprivacy']
  
  # Alternative resource bundle approach (commented out for Melos)
  # s.resource_bundles = {
  #   'ultralytics_yolo_privacy' => ['Resources/PrivacyInfo.xcprivacy'],
  #   'ultralytics_yolo_models' => ['Assets/**/*']
  # }
end
