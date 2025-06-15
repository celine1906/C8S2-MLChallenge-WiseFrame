//
//  SkinToneClassification.swift
//  testingvision
//
//  Created by Regina Celine Adiwinata on 13/06/25.
//

import CoreML
import UIKit

class SkinToneClassification: ObservableObject {
    
    func uiImageToPixelBuffer(_ image: UIImage) -> CVPixelBuffer? {
        guard let cgImage = image.cgImage else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height

        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attrs,
            &pixelBuffer
        )

        guard let buffer = pixelBuffer, status == kCVReturnSuccess else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        if let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) {
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        CVPixelBufferUnlockBaseAddress(buffer, .readOnly)

        return buffer
    }

    func classifySkinTone(image: UIImage) -> String? {
        do {
            let config = MLModelConfiguration()
            let model = try SkinToneClassifier3Labels(configuration: config)
            if let pixelBuffer = uiImageToPixelBuffer(image) {
                let prediction = try model.prediction(image: pixelBuffer)
                return prediction.target
            }
        }
        catch {
            print(error)
            
        }
        return nil
    }
    
    func classifySkinTone2(image: UIImage) -> String? {
        do {
            let config = MLModelConfiguration()
            let model = try SkinToneClassifier4Labels(configuration: config)
            if let pixelBuffer = uiImageToPixelBuffer(image) {
                let prediction = try model.prediction(image: pixelBuffer)
                return prediction.target
            }
        }
        catch {
            print(error)
            
        }
        return nil
    }
}
