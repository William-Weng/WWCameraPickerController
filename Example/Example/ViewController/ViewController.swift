//
//  ViewController.swift
//  WWCameraPickerController
//
//  Created by William.Weng on 2021/9/15.
//  ~/Library/Caches/org.swift.swiftpm/

import UIKit
import WWPrint
import WWCameraPickerController

final class ViewController: UIViewController {
    
    @IBOutlet weak var zoomSlider: UISlider!
    
    private var cameraViewController: WWCameraViewController?
    private var zoomRate: CGFloat = 0.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        takePhotoAction()
        takeMovieAction()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let viewController = segue.destination as? WWCameraViewController,
              let zoomRange = viewController.cameraZoomRange()
        else {
            return
        }
        
        cameraViewController = viewController
        zoomSlider._setting(value: Float(zoomRange.min), max: Float(zoomRange.max), min: Float(zoomRange.min), isContinuous: true)
    }
    
    @IBAction func startRunning(_ sender: UIButton) { cameraViewController?.startRunning() }
    @IBAction func stopRunning(_ sender: UIButton) { cameraViewController?.stopRunning() }
    @IBAction func capturePhoto(_ sender: UIButton) { cameraViewController?.capturePhoto() }
    @IBAction func flashModeSetting(_ sender: UIButton) { cameraViewController?.flashModeSetting(.on) }
    @IBAction func switchCamera(_ sender: UIButton) { _ = cameraViewController?.switchCamera() }
    @IBAction func previewLayerRateSetting(_ sender: UIButton) { cameraViewController?.previewLayerRateSetting(sessionPreset: .photo, videoGravity: .resizeAspect) }
    @IBAction func caremaZoomIn(_ sender: UIButton) { _ = cameraViewController?.cameraZoomIn(with: 0.5) }
    @IBAction func caremaZoomOut(_ sender: UIButton) { _ = cameraViewController?.cameraZoomOut(with: 0.5) }
    @IBAction func caremaZoom(_ sender: UISlider) { _ = cameraViewController?.cameraZoom(with: 0.5, factor: CGFloat(sender.value)) }
    @IBAction func userAlbum(_ sender: UIButton) { cameraViewController?.album() }
    @IBAction func cameraHDR(_ sender: UIButton) { _ = cameraViewController?.cameraHDR(isEnable: false) }
    @IBAction func startRecording(_ sender: UIButton) { cameraViewController?.startRecording(with: 3) }
    @IBAction func stopRecording(_ sender: UIButton) { cameraViewController?.stopRecording() }
}

// MARK: - 小工具
extension ViewController {
    
    /// 拍照的相關動作 (拍照 => 存照片)
    private func takePhotoAction() {
        
        guard let cameraViewController = cameraViewController else { return }
        
        cameraViewController.takePhoto({ result in
            
            switch result {
            case .failure(let error): wwPrint(error)
            case .success(let photo):
                
                cameraViewController.saveImage(photo._image(), result: { _result in
                    switch _result {
                    case .failure(let error): wwPrint(error)
                    case .success(let isSuccess): wwPrint(isSuccess)
                    }
                })
            }
        })
    }
    
    /// 錄影的相關動作 (錄影片 => 存影片)
    private func takeMovieAction() {
        
        guard let cameraViewController = cameraViewController else { return }
        
        cameraViewController.takeMovie { result in
            switch result {
            case .failure(let error): wwPrint(error)
            case .success(let isSuccess): wwPrint(isSuccess)
            }
        }
    }
}
