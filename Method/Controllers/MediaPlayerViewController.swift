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
    
    var volume = 1.0
    var record: Recording?
    var audioPlayer: AVAudioPlayer!
    
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
  
    func removeFile(){
        do{
            try FileManager.default.removeItem(atPath: NSTemporaryDirectory().appending("media.m41"))
            
        } catch{
            print(error)
        }
    }
    
    func play(){

        let fileURL = record?.fileUrlString
        let reference = Storage.storage().reference(forURL: fileURL!)
        
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent("media.m4a")
        
        // Download to the local filesystem
        let downloadTask = reference.write(toFile: localURL) { url, error in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return
            } else {
                return
            }
        }
        
        downloadTask.observe(.success) { snapshot in
            // Download completed successfully
            do{
                self.audioPlayer = try AVAudioPlayer(contentsOf: localURL)
                self.audioPlayer.delegate = self as? AVAudioPlayerDelegate
                self.audioPlayer.prepareToPlay()
                self.audioPlayer.volume = Float(self.volume)
                self.audioPlayer.play()
            } catch{
                self.audioPlayer = nil
                print(error.localizedDescription)
            }
        }
        
        removeFile()
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)

    }
    
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        play()
    }
    
    
    
}
