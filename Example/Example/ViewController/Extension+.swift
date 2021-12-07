//
//  Extension+.swift
//  Example
//
//  Created by William.Weng on 2021/12/7.
//

import UIKit
import AVKit

// MARK: - UISlider (class function)
extension UISlider {
    
    /// [設定基本數值](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/讓-slider-的數值變成固定數量的整數-e2ef715e3591)
    /// - Parameters:
    ///   - value: 目前顯示的數值
    ///   - max: 最大值
    ///   - min: 最小值
    ///   - isContinuous: 是否手放開才更新圓點位置
    func _setting(value: Float, max: Float = 1.0, min: Float = 0.0, isContinuous: Bool = false) {
        
        self.value = value
        self.maximumValue = max
        self.minimumValue = min
        self.isContinuous = isContinuous
    }
}

// MARK: - AVCapturePhoto (class function)
extension AVCapturePhoto {
    
    /// AVCapturePhoto => Data
    /// - Returns: Data?
    func _fileData() -> Data? { return fileDataRepresentation() }
    
    /// AVCapturePhoto => UIImage
    /// - Parameter scale: CGFloat
    /// - Returns: UIImage?
    func _image(scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        guard let imageData = self._fileData() else { return nil }
        return UIImage(data: imageData, scale: scale)
    }
}
