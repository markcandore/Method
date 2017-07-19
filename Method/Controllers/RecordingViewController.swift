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
        
        
    }
    
    @IBAction func listButtonTapped(_ sender: UIButton) {
    }
    
    
    
}
