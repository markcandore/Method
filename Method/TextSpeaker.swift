//
//  TextSpeaker.swift
//  Method
//
//  Created by Mark Wang on 8/15/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import AVFoundation

class TextSpeaker{
    var utterance: AVSpeechUtterance

    let synthesizer : AVSpeechSynthesizer
    
    init() {
        let tip = Tips()
        utterance = AVSpeechUtterance(string: tip.tip)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        utterance.rate = 0.5
        
        synthesizer = AVSpeechSynthesizer()

    }
    
    func speak(){
        synthesizer.speak(utterance)
    }
    
    func speakText(words: String){
        utterance = AVSpeechUtterance(string: words)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
}
