//
//  ImageCaptureHelper.swift
//  Method
//
//  Created by Mark Wang on 8/1/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import CoreImage

class ImageCaptureHelper{
    static func videoPreviewUiimage(vidURL: URL) -> UIImage! {
        let asset = AVURLAsset(url: vidURL as URL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        let timestamp = CMTime(seconds: 2, preferredTimescale: 60)
        do {
            let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
            return UIImage(cgImage: imageRef)
            
        }
        catch let error as NSError
        {
            print("Image generation failed with error \(error)")
            return nil
        }
    }
    
    static func videoPreviewUiimage(vidURL: URL, duration: TimeInterval) -> UIImage! {
        print("preview")
        let asset = AVURLAsset(url: vidURL as URL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        var defaultImage: UIImage? = nil
        var time = duration
        if time > 10 {
            time = 10
        }
        
        for index in 0 ... Int(time){
            let timestamp = CMTime(seconds: Double(index), preferredTimescale: 1)
            do {
                let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
                let image = UIImage(cgImage: imageRef)
                if hasFace(image: image) == true{
                    return image
                }
                defaultImage = image
            }
            catch let error as NSError
            {
                print("Image generation failed with error \(error)")
                return nil
            }
        }
        
        return defaultImage
    }
    
    static func hasFace(image: UIImage) -> Bool{
        guard let personciImage = CIImage(image: image) else {
            return false
        }
        
        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        let faces = faceDetector?.features(in: personciImage)
        
        if faces?.count != 0{
            return true
        }
        
        return false
    }
}

