//
//  WWCameraPickerController.swift
//  WWCameraPickerController
//
//  Created by William.Weng on 2021/12/7.
//  ~/Library/Caches/org.swift.swiftpm/

import UIKit
import AVFoundation
import PhotosUI

open class WWCameraViewController: UIViewController {
        
    @IBInspectable public var useMovieOutput: Bool = false
    
    private let captureSession = AVCaptureSession()
    private let capturePhotoOutput = AVCapturePhotoOutput()
    private let captureMovieFileOutput = AVCaptureMovieFileOutput()

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

// MARK: - ????????????????????? (??????)
extension WWCameraViewController {
    
    /// ??????????????????
    public func startRunning() { captureSession.startRunning() }
    
    /// ??????????????????
    public func stopRunning() { captureSession.stopRunning() }
    
    /// ??????????????????????????????
    public func isRunning() -> Bool { captureSession.isRunning }
    
    /// ??????????????????
    public func capturePhoto() {
        capturePhotoOutput
            ._setting(isHighResolutionPhotoEnabled: cameraModeSetting.isHighResolution, quality: cameraModeSetting.quality)
            ._capturePhoto(isHighResolutionPhotoEnabled: cameraModeSetting.isHighResolution, flashMode: cameraModeSetting.flashMode, delegate: self)
    }
    
    /// [??????????????????](https://www.jianshu.com/p/ca446523fe07)
    /// - Parameter seconds: [???????????????](https://www.jianshu.com/p/6a1cd03343c9)
    public func startRecording(with seconds: Float64 = .infinity) {
        captureMovieFileOutput.maxRecordedDuration = CMTimeMakeWithSeconds(seconds, preferredTimescale: Int32(1 * NSEC_PER_SEC))
        captureMovieFileOutput.startRecording(to: tempMovieFileUrl(), recordingDelegate: self)
    }
    
    /// ??????????????????
    public func stopRecording() { captureMovieFileOutput.stopRecording() }
    
    /// ??????????????????
    public func switchCamera() -> Result<Bool, Error> { return captureSession._switchCamera() }
    
    /// ?????????????????????????????????
    /// - Parameter photo: Result<AVCapturePhoto, Error>
    public func takePhoto(_ result: @escaping ((Result<AVCapturePhoto, Error>) -> Void)) { takePhotoClosure = result }
    
    /// ???????????????????????????
    /// - Parameter result: Result<Bool, Error>
    public func takeMovie(_ result: @escaping ((Result<Bool, Error>) -> Void)) { takeMovieClosure = result }
    
    /// ??????????????????????????????
    /// - Parameters:
    ///   - image: UIImage?
    ///   - result: Result<Bool, Error>
    public func saveImage(_ image: UIImage?, result: @escaping ((Result<Bool, Error>) -> Void)) {
        
        PHPhotoLibrary.shared()._saveImage(image) { _result in
            switch _result {
            case .failure(let error): result(.failure(error))
            case .success(let isSuccess): result(.success(isSuccess))
            }
        }
    }
    
    /// [????????????????????????????????? / ??????](https://www.jianshu.com/p/9e1661805d74)
    /// - Parameters:
    ///   - sessionPreset: [AVCaptureSession.Preset - 4:3 (.photo) / 16:9 (.high)](https://www.jianshu.com/p/9e1661805d74)
    ///   - videoGravity: [AVLayerVideoGravity - ?????? (.resizeAspectFill) / ?????? (.resizeAspect)]
    public func previewLayerRateSetting(sessionPreset: AVCaptureSession.Preset = .photo, videoGravity: AVLayerVideoGravity = .resizeAspect) {
        captureSession.sessionPreset = sessionPreset
        previewLayer?.videoGravity = videoGravity
    }
    
    /// ???????????????????????????
    /// - Returns: Constant.CameraZoomRange?
    public func cameraZoomRange() -> Constant.CameraZoomRange? { return AVCaptureDevice._default(for: .video)?._zoomRange() }
    
    /// ???????????? (????????????)
    /// - Parameters:
    ///   - rate: ??????
    ///   - factor: ????????????
    /// - Returns: Result<CGFloat?, Error>?
    public func cameraZoom(with rate: CGFloat, factor: CGFloat) -> Result<CGFloat?, Error>? { return AVCaptureDevice._default(for: .video)?._zoom(with: rate, factor: factor) }
    
    /// ???????????? (?????????)
    /// - Parameter rate: ??????
    /// - Returns: Result<CGFloat?, Error>?
    public func cameraZoomIn(with rate: CGFloat) -> Result<CGFloat?, Error>? { return AVCaptureDevice._default(for: .video)?._zoomIn(with: rate) }

    /// ???????????? (?????????)
    /// - Parameter rate: ??????
    /// - Returns: Result<CGFloat?, Error>?
    public func cameraZoomOut(with rate: CGFloat) -> Result<CGFloat?, Error>? { return AVCaptureDevice._default(for: .video)?._zoomOut(with: rate) }
    
    /// [??????HDR - High Dynamic Range Imaging](https://zh.wikipedia.org/zh-tw/?????????????????????)
    /// - Parameter isEnable: Bool
    /// - Returns: Result<Bool, Error>
    public func cameraHDR(isEnable: Bool) -> Result<Bool, Error>? { return AVCaptureDevice._default(for: .video)?._HDR(isEnable: isEnable) }
    
    /// ????????????ViewController
    /// - Parameters:
    ///   - animated: Bool
    ///   - completion: (() -> Void)?
    public func album(delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate)? = nil, animated: Bool = true, completion: (() -> Void)? = nil) {
        let imagePickerController = UIImagePickerController._photoLibrary(delegate: delegate)
        self.present(imagePickerController, animated: animated) { completion?() }
    }
}

// MARK: - ????????????????????? (??????)
extension WWCameraViewController {
    
    /// ?????????????????????
    /// - Parameter flashMode: AVCaptureDevice.FlashMode
    public func flashModeSetting(_ flashMode: AVCaptureDevice.FlashMode = .auto) { cameraModeSetting.flashMode = flashMode }
    
    /// ??????????????????????????????
    /// - Parameter isHighResolution: Bool
    public func highResolutionSetting(_ isHighResolution: Bool = true) { cameraModeSetting.isHighResolution = isHighResolution }
    
    /// ??????????????????
    /// - Parameter quality: AVCapturePhotoOutput.QualityPrioritization
    public func qualitySetting(_ quality: AVCapturePhotoOutput.QualityPrioritization = .quality) { cameraModeSetting.quality = quality }
}

// MARK: - ?????????
extension WWCameraViewController {
    
    private func initSetting() {
        _ = photoSetting()
        if (useMovieOutput) { _ = movieSetting() }
    }
    
    /// [???????????? => NSCameraUsageDescription](https://medium.com/????????????-swift-ios-app-????????????/qrcode?????????-24e086df902c)
    /// - Returns: Bool
    private func photoSetting() -> Bool {
        
        guard let device = AVCaptureDevice._default(for: .video),
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

    /// [??????????????? => NSMicrophoneUsageDescription](https://ithelp.ithome.com.tw/articles/10206444)
    /// - UIFileSharingEnabled
    /// - Returns: Bool
    private func movieSetting() -> Bool {
        
        guard let device = AVCaptureDevice._default(for: .audio),
              let input = try? device._captureInput().get(),
              captureSession._canAddInput(input),
              captureSession._canAddOutput(captureMovieFileOutput)
        else {
            return false
        }
        
        return true
    }
    
    /// ????????????????????????URL (~/tmp/ooxx.mov)
    /// - Parameter name: String
    /// - Returns: URL
    private func tempMovieFileUrl(with name: String = Date().description) -> URL {
        return FileManager.default._temporaryDirectory().appendingPathComponent("\(name).mov")
    }
}

