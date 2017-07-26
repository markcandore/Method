//
//  MediaPlayerViewController.swift
//  Method
//
//  Created by Mark Wang on 7/21/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import FirebaseStorage

class MediaPlayerViewController: UIViewController {
    
 
    var record: Recording?
    var audioPlayer: AVAudioPlayer?
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var transcriptTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let record = record{
            self.nameLabel.text = record.title
            self.dateLabel.text = record.getDateString()
            self.transcriptTextView.text = record.transcript
        }
    }
    
    @IBAction func backButton(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
}
