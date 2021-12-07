//
//  Constant.swift
//  WWCameraPickerController
//
//  Created by William.Weng on 2021/12/7.
//

import UIKit
import AVFoundation

public class Constant {
    public typealias CameraZoomRange = (max: CGFloat, min: CGFloat)                         // 鏡頭縮放範圍
}

// MARK: - typealias
extension Constant {
    typealias ScreenBoundsInfomation = (width: CGFloat, height: CGFloat, scale: CGFloat)    // iPhone的裝置螢幕大小 (寬/高/比例)
    typealias WideAngleCamera = (front: AVCaptureDevice?, back: AVCaptureDevice?)           // 前後鏡頭
}

// MARK: - 自訂常數
extension Constant {
    
    /// 自訂錯誤
    enum MyError: Error, LocalizedError {
        
        var errorDescription: String { errorMessage() }

        case unknown
        case unauthorization
        case isEmpty
        case isNotRunning
        
        /// 顯示錯誤說明
        /// - Returns: String
        private func errorMessage() -> String {

            switch self {
            case .unknown: return "未知錯誤"
            case .unauthorization: return "尚未授權"
            case .isEmpty: return "資料是空的"
            case .isNotRunning: return "沒有在運作"
            }
        }
    }
    
    /// [統一類型標識 - Uniform Type Identifiers](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html)
    enum UTI: String {
        case data = "public.data"               // [全部](https://gist.github.com/ddeville/1527517)
        case text = "public.plain-text"         // 純文字檔 => .txt
        case pdf = "com.adobe.pdf"              // PDF文件 => .pdf
        case image = "public.image"             // 圖片 => 總稱
        case movie = "public.movie"             // 影片 => 總稱
        case png = "public.png"                 // 圖片 => .png
        case jpeg = "public.jpeg"               // 圖片 => .jpg
    }
}
