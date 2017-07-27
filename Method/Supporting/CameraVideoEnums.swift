//
//  CameraVideoEnums.swift
//  Method
//
//  Created by Mark Wang on 7/27/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import Foundation

public enum VideoGravity{
    case resize
    case resizeAspect
    case resizeAspectFill
}

public enum CameraSelection{
    case rear
    case front
}
public enum VideoQuality{
    /// AVCaptureSessionPresetHigh
    case high
    
    /// AVCaptureSessionPresetMedium
    case medium
    
    /// AVCaptureSessionPresetLow
    case low
    
    /// AVCaptureSessionPreset352x288
    case resolution352x288
    
    /// AVCaptureSessionPreset640x480
    case resolution640x480
    
    /// AVCaptureSessionPreset1280x720
    case resolution1280x720
    
    /// AVCaptureSessionPreset1920x1080
    case resolution1920x1080
    
    /// AVCaptureSessionPreset3840x2160
    case resolution3840x2160
    
    /// AVCaptureSessionPresetiFrame960x540
    case iframe960x540
    
    /// AVCaptureSessionPresetiFrame1280x720
    case iframe1280x720
}
