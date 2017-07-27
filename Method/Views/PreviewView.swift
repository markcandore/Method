//
//  PreviewView.swift
//  Method
//
//  Created by Mark Wang on 7/27/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import AVFoundation
import UIKit

class PreviewView: UIView{
    private var gravity: VideoGravity = .resizeAspect
    
    init(frame: CGRect, videoGravity: VideoGravity){
        gravity = videoGravity
        super.init(frame: frame)
        self.backgroundColor = UIColor.darkGray
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        let previewlayer = layer as! AVCaptureVideoPreviewLayer
        switch gravity {
        case .resize:
            previewlayer.videoGravity = AVLayerVideoGravityResize
        case .resizeAspect:
            previewlayer.videoGravity = AVLayerVideoGravityResizeAspect
        case .resizeAspectFill:
            previewlayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        }
        return previewlayer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    override class var layerClass : AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

}
