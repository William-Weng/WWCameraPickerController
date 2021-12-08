//
//  Extension+.swift
//  WWCameraPickerController
//
//  Created by William.Weng on 2021/12/7.
//

import UIKit
import AVFoundation
import Photos
import PhotosUI

// MARK: - AVCaptureDevice (static function)
extension AVCaptureDevice {
    
    /// 取得預設影音裝置 (NSCameraUsageDescription / NSMicrophoneUsageDescription)
    static func _default(for type: AVMediaType) -> AVCaptureDevice? { return AVCaptureDevice.default(for: type) }
    
    /// 取得前後相機 => AVCaptureDevice
    /// - Returns: Constant.WideAngleCamera
    static func _wideAngleCamera() -> Constant.WideAngleCamera {
        
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified).devices

        var videoDeivce: (front: AVCaptureDevice?, back: AVCaptureDevice?) = (nil, nil)
        
        for device in devices {
            switch device.position {
            case .front: videoDeivce.front = device
            case .back: videoDeivce.back = device
            case .unspecified: break
            @unknown default: fatalError()
            }
        }
        
        return videoDeivce
    }
}

// MARK: - AVCaptureDevice (class function)
extension AVCaptureDevice {
    
    /// 判斷鏡頭的位置 (前後) => .front / .back
    func _videoPosition() -> AVCaptureDevice.Position { return self.position }
    
    /// 取得裝置的Input => NSCameraUsageDescription / NSMicrophoneUsageDescription
    func _captureInput() -> Result<AVCaptureDeviceInput, Error> {
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: self)
            return .success(deviceInput)
        } catch {
            return .failure(error)
        }
    }
    
    /// [取得鏡頭縮放範圍](https://developer.apple.com/documentation/avfoundation/avcapturedevice/2865758-maxavailablevideozoomfactor)
    /// - Returns: CameraZoomRange
    func _zoomRange() -> Constant.CameraZoomRange {
        return (max: self.maxAvailableVideoZoomFactor, min: self.minAvailableVideoZoomFactor)
    }
    
    /// [鏡頭放大](https://www.cxyzjd.com/article/hherima/100068931)
    /// - Parameters:
    ///   - rate: 比率
    ///   - isSmooth: [是否要平滑縮放？](https://stackoverflow.com/questions/33180564/pinch-to-zoom-camera)
    /// - Returns: Result<CGFloat?, Error> => 回傳videoZoomFactor
    func _zoomIn(with rate: CGFloat, isSmooth: Bool = true) -> Result<CGFloat?, Error> {
        
        let maxZoomFactor = self.maxAvailableVideoZoomFactor
        let currentVideoZoomFactor = self.videoZoomFactor
        
        if (maxZoomFactor < currentVideoZoomFactor) { return .success(nil) }
        
        return _zoom(with: rate, factor: min(currentVideoZoomFactor + rate, maxZoomFactor), isSmooth: isSmooth)
    }
    
    /// [鏡頭縮小](https://www.coder.work/article/7577791)
    /// - Parameters:
    ///   - rate: 比率
    ///   - isSmooth: [是否要平滑縮放？](https://stackoverflow.com/questions/33180564/pinch-to-zoom-camera)
    /// - Returns: Result<CGFloat?, Error> => 回傳videoZoomFactor
    func _zoomOut(with rate: CGFloat, isSmooth: Bool = true) -> Result<CGFloat?, Error> {
        
        let minZoomFactor = self.minAvailableVideoZoomFactor
        let currentVideoZoomFactor = self.videoZoomFactor
        
        if (currentVideoZoomFactor < minZoomFactor) { return .success(nil) }
        
        return _zoom(with: rate, factor: max(currentVideoZoomFactor - rate, minZoomFactor), isSmooth: isSmooth)
    }
    
    /// [鏡頭縮放](https://developer.apple.com/documentation/avfoundation/avcapturedevice/1624614-ramp)
    /// - Parameters:
    ///   - rate: [比率](https://blog.csdn.net/u012581760/article/details/80936741)
    ///   - factor: [倍率因子](https://stackoverflow.com/questions/45227163/using-avcapturedevice-zoom-settings)
    ///   - isSmooth: [是否要平滑縮放？](https://stackoverflow.com/questions/33180564/pinch-to-zoom-camera)
    /// - Returns: Result<Bool, Error>
    func _zoom(with rate: CGFloat, factor: CGFloat, isSmooth: Bool = false) -> Result<CGFloat?, Error> {
                
        let result = self._lockForConfiguration { () -> CGFloat? in
            
            if (isSmooth) {
                self.ramp(toVideoZoomFactor: factor, withRate: Float(rate))
            } else {
                self.videoZoomFactor = factor
            }
            
            return self.videoZoomFactor
        }
        
        return result
    }
    
    /// [停止鏡頭縮放](https://iter01.com/478255.html)
    /// - Returns: Result<Bool, Error>
    func _zoomCancel() -> Result<Bool, Error> {
        
        let result = self._lockForConfiguration { () -> Bool in
            self.cancelVideoZoomRamp()
            return true
        }
        
        return result
    }
    
    /// [啟動HDR - High Dynamic Range Imaging](https://zh.wikipedia.org/zh-tw/高动态范围成像)
    /// - Parameter isEnable: Bool
    /// - Returns: Result<Bool, Error>
    func _HDR(isEnable: Bool = true) -> Result<Bool, Error> {
        
        let result = self._lockForConfiguration { () -> Bool in
            
            self.automaticallyAdjustsVideoHDREnabled = false
            self.isVideoHDREnabled = isEnable
            
            return self.isVideoHDREnabled
        }
        
        return result
    }
    
    /// [lock住設備 => 硬體參數設定](https://objccn.io/issue-23-1/)
    /// - Returns: Result<T, Error>
    func _lockForConfiguration<T>(_ block: @escaping (() -> T)) -> Result<T, Error> {
        
        defer { unlockForConfiguration() }
        
        do {
            try lockForConfiguration()
            return .success(block())
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - AVCaptureSession (class function)
extension AVCaptureSession {
    
    /// 產生、設定AVCaptureVideoPreviewLayer
    /// - Parameters:
    ///   - frame: CGRect
    ///   - videoGravity: AVLayerVideoGravity => .resizeAspectFill
    /// - Returns: AVCaptureVideoPreviewLayer
    func _previewLayer(with frame: CGRect, videoGravity: AVLayerVideoGravity = .resizeAspectFill) -> AVCaptureVideoPreviewLayer {
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: self)
        
        previewLayer.frame = frame
        previewLayer.videoGravity = videoGravity
        
        return previewLayer
    }
    
    /// 將影音的Input加入Session
    /// - Parameter input: AVCaptureInput
    /// - Returns: Bool
    func _canAddInput(_ input: AVCaptureInput) -> Bool {
        guard self.canAddInput(input) else { return false }
        self.addInput(input); return true
    }
    
    /// 加入手機設備 (相機、麥克風…)
    /// - Parameter types: Set<AVMediaType> => [.audio, .video]
    /// - Returns: Result<Bool, Error>
    func _canAddDevices(with devices: [AVCaptureDevice]) -> Result<Bool, Error> {
                
        var isSuccess = false
        var error: Error?
        
        devices.forEach { device in
            
            switch device._captureInput() {
            case .failure(let _error): error = _error; return
            case .success(let _input):
                isSuccess = self._canAddInput(_input)
                if (false == isSuccess) { return }
            }
        }
        
        if let error = error { return .failure(error) }
        return .success(isSuccess)
    }
    
    /// 將影音的Output加入Session
    /// - Parameter input: AVCaptureOutput
    /// - Returns: Bool
    func _canAddOutput(_ output: AVCaptureOutput) -> Bool {
        guard self.canAddOutput(output) else { return false }
        self.addOutput(output); return true
    }
    
    /// 清除[AVCaptureInput]
    func _removeInputs(_ inputs: [AVCaptureInput]) {
        for input in inputs { self.removeInput(input) }
    }
    
    /// 切換前後鏡頭 (isRunning才會換)
    /// - Returns: Result<Bool, Error>
    func _switchCamera() -> Result<Bool, Error> {
        
        guard self.isRunning,
              let frontCamera = AVCaptureDevice._wideAngleCamera().front,
              let backCamera = AVCaptureDevice._wideAngleCamera().back
        else {
            return .failure(Constant.MyError.isNotRunning)
        }
        
        self.beginConfiguration()
        defer { self.commitConfiguration() }
        
        var result = Result { return false }
        
        self.inputs.forEach { _input in
            
            guard let input = _input as? AVCaptureDeviceInput else { return }
            
            switch input.device.position {
            case .front:
                self._removeInputs([_input])
                result = self._canAddDevices(with: [backCamera]); return
            case .back:
                self._removeInputs([_input])
                result = self._canAddDevices(with: [frontCamera]); return
            default: return
            }
        }
        
        return result
    }
}

// MARK: - AVCapturePhotoOutput (class function)
extension AVCapturePhotoOutput {
    
    /// 擷圖 => 拍照 => photoOutput(_:didFinishProcessingPhoto:error:)
    /// - Parameters:
    ///   - isHighResolutionPhotoEnabled: 高解析度
    ///   - flashMode: 閃光燈 => 自動
    ///   - delegate: AVCapturePhotoCaptureDelegate
    ///   - completion: (() -> Void)?
    func _capturePhoto(isHighResolutionPhotoEnabled: Bool = true, flashMode: AVCaptureDevice.FlashMode = .auto, delegate: AVCapturePhotoCaptureDelegate, completion: (() -> Void)? = nil) {
        
        self.isHighResolutionCaptureEnabled = isHighResolutionPhotoEnabled
        
        let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoSettings.isHighResolutionPhotoEnabled = isHighResolutionPhotoEnabled
        photoSettings.flashMode = flashMode
        
        self.capturePhoto(with: photoSettings, delegate: delegate)
        
        completion?()
    }
    
    /// [基本參數設定](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avcam_building_a_camera_app)
    /// - Parameters:
    ///   - isHighResolutionPhotoEnabled: 高解析度
    ///   - quality: 拍照品質
    func _setting(isHighResolutionPhotoEnabled: Bool = true, quality: AVCapturePhotoOutput.QualityPrioritization) -> Self {
        
        self.isHighResolutionCaptureEnabled = isHighResolutionPhotoEnabled
        self.maxPhotoQualityPrioritization = quality
        
        self.isLivePhotoCaptureEnabled = self.isLivePhotoCaptureSupported
        self.isDepthDataDeliveryEnabled = self.isDepthDataDeliverySupported
        self.isPortraitEffectsMatteDeliveryEnabled = self.isPortraitEffectsMatteDeliverySupported
        self.enabledSemanticSegmentationMatteTypes = self.availableSemanticSegmentationMatteTypes
        
        return self
    }
}

// MARK: - UIImagePickerController (static function)
extension UIImagePickerController {
    
    /// 產生UIImagePickerController基本型
    /// - Parameters:
    ///   - delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate
    ///   - sourceType: 來源的樣式 => 相簿 / 鏡頭
    ///   - mediaTypes: 讀取的樣式 => 圖片 / 影片
    ///   - modalTransitionStyle: 轉場的樣式
    ///   - allowsEditing: 可不可以編譯
    ///   - tintColor: NavigationBar的TintColor
    /// - Returns: UIImagePickerController
    static func _build(delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate)?, sourceType: UIImagePickerController.SourceType, mediaTypes: [Constant.UTI], modalTransitionStyle: UIModalTransitionStyle = .coverVertical, allowsEditing: Bool = false, tintColor: UIColor = .systemBlue) -> UIImagePickerController {
        
        let pickerController = UIImagePickerController()
        
        pickerController.delegate = delegate
        pickerController.mediaTypes = mediaTypes.map { $0.rawValue }
        pickerController.modalTransitionStyle = modalTransitionStyle
        pickerController.sourceType = sourceType
        pickerController.allowsEditing = allowsEditing
        pickerController.navigationBar.tintColor = tintColor
        
        return pickerController
    }
    
    /// 產生圖片選取框 => 相簿 (NSCameraUsageDescription + NSMicrophoneUsageDescription)
    /// - Parameters:
    ///   - delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate
    ///   - modalTransitionStyle: 轉場的樣式
    ///   - allowsEditing: 可不可以編譯圖片
    ///   - tintColor: NavigationBar的TintColor
    /// - Returns: UIImagePickerController
    static func _photoLibrary(delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate)? = nil, modalTransitionStyle: UIModalTransitionStyle = .coverVertical, allowsEditing: Bool = false, tintColor: UIColor = .systemBlue) -> UIImagePickerController {
        return Self._build(delegate: delegate, sourceType: .photoLibrary, mediaTypes: [.image], modalTransitionStyle: modalTransitionStyle, allowsEditing: allowsEditing, tintColor: tintColor)
    }
}

// MARK: - PHPhotoLibrary (class function)
extension PHPhotoLibrary {
    
    /// 儲存圖片到使用者相簿 - PHPhotoLibrary.shared()
    /// - info.plist => NSPhotoLibraryAddUsageDescription / NSPhotoLibraryUsageDescription
    /// - Parameters:
    ///   - image: 要儲存的圖片
    ///   - result: Result<Bool, Error>
    func _saveImage(_ image: UIImage?, result: @escaping (Result<Bool, Error>) -> Void) {
        
        guard let image = image else { result(.failure(Constant.MyError.isEmpty)); return }
        
        self.performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: { (isSuccess, error) in
            if let error = error { result(.failure(error)); return }
            result(.success(isSuccess))
        })
    }
    
    /// [複製影片到使用者相簿](https://stackoverflow.com/questions/29482738/swift-save-video-from-nsurl-to-user-camera-roll)
    /// - Parameters:
    ///   - url: 要複製的影片URL
    ///   - result: Result<Bool, Error>
    func _saveVideo(at url: URL, result: @escaping (Result<Bool, Error>) -> Void) {
        
        self.performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        } completionHandler: { isSuccess, error in
            if let error = error { result(.failure(error)); return }
            result(.success(isSuccess))
        }
    }
}

// MARK: - FileManager (class function)
extension FileManager {
        
    /// User的「暫存」資料夾
    /// - => ~/tmp
    /// - Returns: URL
    func _temporaryDirectory() -> URL { return URL(fileURLWithPath: NSTemporaryDirectory()) }
    
    /// 移除檔案
    /// - Parameter atURL: URL
    /// - Returns: Result<Bool, Error>
    func _removeFile(at atURL: URL?) -> Result<Bool, Error> {
        
        guard let atURL = atURL else { return .success(false) }
        
        do {
            try removeItem(at: atURL)
            return .success(true)
        } catch  {
            return .failure(error)
        }
    }
}
