//
//  RecordingViewController.swift
//  Method
//
//  Created by Mark Wang on 7/19/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import Foundation
import UIKit
import Speech

class RecordingViewController: UIViewController, SFSpeechRecognizerDelegate {

    
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    
    var isRecording: Bool = false
    
    @IBOutlet weak var transcriptTextView: UITextView!

    @IBOutlet weak var recordButton: UIButton!
    
    @IBOutlet weak var listButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning(){
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func recordButtonTapped(_ sender: UIButton) {
        if isRecording == false{
            recordAndRecognizeSpeech()
            isRecording = true
        } else {
            audioEngine.stop()
            isRecording = false
        }
        
        
    }
    
    @IBAction func listButtonTapped(_ sender: UIButton) {
    }
    
    func recordAndRecognizeSpeech()-> Void{
        guard let node = audioEngine.inputNode else { return }
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        }   catch {
            return print(error)
        }
        
        guard let myRecognizer = SFSpeechRecognizer() else {
            return
        }
        
        if !myRecognizer.isAvailable {
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: {result, error in
            if let result = result {
                let bestString = result.bestTranscription.formattedString
                self.transcriptTextView.text = bestString
            } else if let error = error {
                print(error)
            }
        })
    }
    
}
