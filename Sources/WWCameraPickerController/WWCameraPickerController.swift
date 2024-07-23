//
//  WWCameraPickerController.swift
//  WWCameraPickerController
//
//  Created by William.Weng on 2021/12/7.
//

import UIKit
import AVFoundation
import PhotosUI

open class WWCameraViewController: UIViewController {
        
    @IBInspectable public var useMovieOutput: Bool = false
        
    private let captureSession = AVCaptureSession()
    private let capturePhotoOutput = AVCapturePhotoOutput()
    private let captureMovieFileOutput = AVCaptureMovieFileOutput()

    private var defaultPosition: AVCaptureDevice.Position = .unspecified
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var cameraModeSetting: (flashMode: AVCaptureDevice.FlashMode, isHighResolution: Bool, quality: AVCapturePhotoOutput.QualityPrioritization) = (.auto, true, .quality)
    
    private var takePhotoClosure: ((Result<AVCapturePhoto, Error>) -> Void)?
    private var takeMovieClosure: ((Result<Bool, Error>) -> Void)?

    public override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension WWCameraViewController: AVCapturePhotoCaptureDelegate {
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error { takePhotoClosure?(.failure(error)); return }
        takePhotoClosure?(.success(photo))
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension WWCameraViewController: AVCaptureFileOutputRecordingDelegate {
    
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        fileOutputAction(output, didFinishRecordingTo: outputFileURL, from: connections, error: error)
    }
}

// MARK: - 開放使用的函數 (動作)
public extension WWCameraViewController {
    
    /// 啟動相機預覽
    func startRunning() {
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    /// 關閉相機預覽
    func stopRunning() { captureSession.stopRunning() }
    
    /// 相機預覽是否在運作？
    func isRunning() -> Bool { captureSession.isRunning }
    
    /// 執行拍照功能
    func capturePhoto() {
        capturePhotoOutput
            ._setting(isHighResolutionPhotoEnabled: cameraModeSetting.isHighResolution, quality: cameraModeSetting.quality)
            ._capturePhoto(isHighResolutionPhotoEnabled: cameraModeSetting.isHighResolution, flashMode: cameraModeSetting.flashMode, delegate: self)
    }
    
    /// [執行錄影功能](https://www.jianshu.com/p/ca446523fe07)
    /// - Parameter seconds: [最多錄幾秒](https://www.jianshu.com/p/6a1cd03343c9)
    func startRecording(with seconds: Float64 = .infinity) {
        captureMovieFileOutput.maxRecordedDuration = CMTimeMakeWithSeconds(seconds, preferredTimescale: Int32(1 * NSEC_PER_SEC))
        captureMovieFileOutput.startRecording(to: tempMovieFileUrl(), recordingDelegate: self)
    }
    
    /// 停止錄影功能
    func stopRecording() { captureMovieFileOutput.stopRecording() }
    
    /// 切換前後鏡頭
    func switchCamera() -> Result<Bool, Error> { return captureSession._switchCamera() }
    
    /// 取得拍攝相片的相關資訊
    /// - Parameter photo: Result<AVCapturePhoto, Error>
    func takePhoto(_ result: @escaping ((Result<AVCapturePhoto, Error>) -> Void)) { takePhotoClosure = result }
    
    /// 取得錄影的相關資訊
    /// - Parameter result: Result<Bool, Error>
    func takeMovie(_ result: @escaping ((Result<Bool, Error>) -> Void)) { takeMovieClosure = result }
    
    /// 儲存圖片到使用者相簿
    /// - Parameters:
    ///   - image: UIImage?
    ///   - result: Result<Bool, Error>
    func saveImage(_ image: UIImage?, result: @escaping ((Result<Bool, Error>) -> Void)) {
        
        PHPhotoLibrary.shared()._saveImage(image) { _result in
            switch _result {
            case .failure(let error): result(.failure(error))
            case .success(let isSuccess): result(.success(isSuccess))
            }
        }
    }
    
    /// [改變輸出畫面的預設比例 / 畫質](https://www.jianshu.com/p/9e1661805d74)
    /// - Parameters:
    ///   - sessionPreset: [AVCaptureSession.Preset - 4:3 (.photo) / 16:9 (.high)](https://www.jianshu.com/p/9e1661805d74)
    ///   - videoGravity: [AVLayerVideoGravity - 滿版 (.resizeAspectFill) / 比例 (.resizeAspect)]
    func previewLayerRateSetting(sessionPreset: AVCaptureSession.Preset = .photo, videoGravity: AVLayerVideoGravity = .resizeAspect) {
        captureSession.sessionPreset = sessionPreset
        previewLayer?.videoGravity = videoGravity
    }
    
    /// 取得鏡頭的縮放範圍
    /// - Returns: Constant.CameraZoomRange?
    func cameraZoomRange() -> Constant.CameraZoomRange? { return AVCaptureDevice._default(for: .video)?._zoomRange() }
    
    /// 鏡頭縮放 (沒有動態)
    /// - Parameters:
    ///   - rate: 比率
    ///   - factor: 比率因子
    /// - Returns: Result<CGFloat?, Error>?
    func cameraZoom(with rate: CGFloat, factor: CGFloat) -> Result<CGFloat?, Error>? { return AVCaptureDevice._default(for: .video)?._zoom(with: rate, factor: factor) }
    
    /// 鏡頭放大 (有動態)
    /// - Parameter rate: 比率
    /// - Returns: Result<CGFloat?, Error>?
    func cameraZoomIn(with rate: CGFloat) -> Result<CGFloat?, Error>? { return AVCaptureDevice._default(for: .video)?._zoomIn(with: rate) }

    /// 鏡頭縮小 (有動態)
    /// - Parameter rate: 比率
    /// - Returns: Result<CGFloat?, Error>?
    func cameraZoomOut(with rate: CGFloat) -> Result<CGFloat?, Error>? { return AVCaptureDevice._default(for: .video)?._zoomOut(with: rate) }
    
    /// [啟動HDR - High Dynamic Range Imaging](https://zh.wikipedia.org/zh-tw/高动态范围成像)
    /// - Parameter isEnable: Bool
    /// - Returns: Result<Bool, Error>
    func cameraHDR(isEnable: Bool) -> Result<Bool, Error>? { return AVCaptureDevice._default(for: .video)?._HDR(isEnable: isEnable) }
    
    /// 產生相簿ViewController
    /// - Parameters:
    ///   - animated: Bool
    ///   - completion: (() -> Void)?
    func album(delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate)? = nil, animated: Bool = true, completion: (() -> Void)? = nil) {
        let imagePickerController = UIImagePickerController._photoLibrary(delegate: delegate)
        self.present(imagePickerController, animated: animated) { completion?() }
    }
}

// MARK: - 開放使用的函數 (設定)
public extension WWCameraViewController {
    
    /// 設定一開始的鏡頭位置 (設定一開始起動的鏡頭位置)
    /// - Parameter defaultPosition: AVCaptureDevice.Position
    func defaultPosition(_ defaultPosition: AVCaptureDevice.Position) {
        self.defaultPosition = defaultPosition
    }
    
    /// 設定閃光燈模式
    /// - Parameter flashMode: AVCaptureDevice.FlashMode
    func flashModeSetting(_ flashMode: AVCaptureDevice.FlashMode = .auto) { cameraModeSetting.flashMode = flashMode }
    
    /// 設定使用高解析度模式
    /// - Parameter isHighResolution: Bool
    func highResolutionSetting(_ isHighResolution: Bool = true) { cameraModeSetting.isHighResolution = isHighResolution }
    
    /// 設定拍照品質
    /// - Parameter quality: AVCapturePhotoOutput.QualityPrioritization
    func qualitySetting(_ quality: AVCapturePhotoOutput.QualityPrioritization = .quality) { cameraModeSetting.quality = quality }
}

// MARK: - 小工具
private extension WWCameraViewController {
    
    /// 初始化設定
    func initSetting() {
        _ = photoSetting(position: defaultPosition)
        if (useMovieOutput) { _ = movieSetting() }
    }
    
    /// [取得鏡頭 => NSCameraUsageDescription](https://medium.com/彼得潘的-swift-ios-app-開發教室/qrcode掃起來-24e086df902c)
    /// - Parameter position: AVCaptureDevice.Position
    /// - Returns: Bool
    func photoSetting(position: AVCaptureDevice.Position) -> Bool {
                
        guard let device = defaultCamera(position: position),
              let input = try? device._captureInput().get(),
              let _previewLayer = Optional.some(captureSession._previewLayer(with: view.bounds, videoGravity: .resizeAspect)),
              captureSession._canAddInput(input),
              captureSession._canAddOutput(capturePhotoOutput)
        else {
            return false
        }
        
        previewLayer = _previewLayer
        view.layer.addSublayer(_previewLayer)
        
        return true
    }
    
    /// 指定預設的鏡頭 (前 / 後 / 預設)
    /// - Parameter position: AVCaptureDevice.Position
    /// - Returns: AVCaptureDevice?
    func defaultCamera(position: AVCaptureDevice.Position = .unspecified) -> AVCaptureDevice? {
        
        let defaultDevice = AVCaptureDevice._default(for: .video)
        let wideAngleDevices = AVCaptureDevice._wideAngleCamera()
        
        switch position {
        case .front: return wideAngleDevices.front
        case .back: return wideAngleDevices.back
        case .unspecified: return defaultDevice
        }
    }
    
    /// [取得麥克風 => NSMicrophoneUsageDescription](https://ithelp.ithome.com.tw/articles/10206444)
    /// - UIFileSharingEnabled
    /// - Returns: Bool
    func movieSetting() -> Bool {
        
        guard let device = AVCaptureDevice._default(for: .audio),
              let input = try? device._captureInput().get(),
              captureSession._canAddInput(input),
              captureSession._canAddOutput(captureMovieFileOutput)
        else {
            return false
        }
        
        return true
    }
    
    /// 產生要暫存影片的URL (~/tmp/ooxx.mov)
    /// - Parameter name: String
    /// - Returns: URL
    func tempMovieFileUrl(with name: String = Date().description) -> URL {
        return FileManager.default._temporaryDirectory().appendingPathComponent("\(name).mov")
    }
    
    /// 處理檔案輸出的功能 (影片)
    /// - Parameters:
    ///   - output: AVCaptureFileOutput
    ///   - outputFileURL: URL
    ///   - connections: [AVCaptureConnection]
    ///   - error: Error?
    func fileOutputAction(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if let error = error { self.takeMovieClosure?(.failure(error)) }
        
        PHPhotoLibrary.shared()._saveVideo(at: outputFileURL) { result in
            
            _ = FileManager.default._removeFile(at: outputFileURL)
            
            switch result {
            case .failure(let error): self.takeMovieClosure?(.failure(error))
            case .success(let isSuccess): self.takeMovieClosure?(.success(isSuccess))
            }
        }
    }
}

