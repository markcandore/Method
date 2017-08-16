//
//  AudioSessionCommandHelper.swift
//  Method
//
//  Created by Mark Wang on 8/3/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import Foundation
import AVFoundation
class AudioSessionCommandHelper {
 
    class func setAudioSessionCategoryRecording(){
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)

        } catch{
            return
        }
    }
    
    class func setAudioSessionCategoryPlayback(){
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setMode(AVAudioSessionModeMoviePlayback)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
            
        } catch{
            return
        }
    }
   
    
}
