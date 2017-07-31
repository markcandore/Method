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
import AVKit
import FirebaseStorage

class MediaPlayerViewController: UIViewController {
    
    var volume = 1.0
    var record: Recording?
    var audioPlayer: AVAudioPlayer!
    var videoPlayer: AVPlayer?
    var playerController : AVPlayerViewController?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var transcriptTextView: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        play()
        /*
        self.view.backgroundColor = UIColor.gray
        player = AVPlayer(url: URL(record?.videoURL))
        playerController = AVPlayerViewController()
        
        guard player != nil && playerController != nil else {
            return
        }
        playerController!.showsPlaybackControls = false
        
        playerController!.player = player!
        self.addChildViewController(playerController!)
        self.view.addSubview(playerController!.view)
        playerController!.view.frame = view.frame
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player!.currentItem)
         */
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /*
        if let record = record{
            self.nameLabel.text = record.title
            //self.dateLabel.text = record.getDateString()
            self.transcriptTextView.text = record.transcript
        }
        play()
 */
    }
  
    func removeFile(){
        do{
            try FileManager.default.removeItem(atPath: NSTemporaryDirectory().appending("audio.m4a"))
            try FileManager.default.removeItem(atPath: NSTemporaryDirectory().appending("video.mov"))
            
        } catch{
            print(error)
        }
    }
    
    func play(){
        print("play tapped")
        
        let audioURL = record?.audioURL
        let audioRef = Storage.storage().reference(forURL: audioURL!)
        let localAudioURL = FileManager.default.temporaryDirectory.appendingPathComponent("audio.m4a")
 
        let videoURL = record?.videoURL
        let videoRef = Storage.storage().reference(forURL: videoURL!)
        let localVideoURL = FileManager.default.temporaryDirectory.appendingPathComponent("video.mov")
        
        
        // Download to the local filesystem
        let downloadAudioTask = audioRef.write(toFile: localAudioURL) { url, error in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return
            } else {
                return
            }
        }
 
        let downloadVideoTask = videoRef.write(toFile: localVideoURL) { url, error in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return
            } else {
                return
            }
        }
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        
        downloadAudioTask.observe(.success) { snapshot in
            // Download completed successfully
            print("audio download success")
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        downloadVideoTask.observe(.success) { snapshot in
            // Download completed successfully
            print("video download success")
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main){
            do{
                self.audioPlayer = try AVAudioPlayer(contentsOf: localAudioURL)
                self.videoPlayer = AVPlayer(url: localVideoURL)
                
                self.playerController = AVPlayerViewController()
                self.playerController!.showsPlaybackControls = false
                
                self.audioPlayer.delegate = self as? AVAudioPlayerDelegate
                self.audioPlayer.prepareToPlay()
                self.audioPlayer.volume = Float(self.volume)
 
                self.playerController!.player = self.videoPlayer
                
                self.addChildViewController(self.playerController!)
                self.view.addSubview(self.playerController!.view)
                self.playerController!.view.frame = self.view.frame
                NotificationCenter.default.addObserver(self, selector: #selector(self.playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.videoPlayer!.currentItem)
                
                self.audioPlayer.play()
                self.videoPlayer?.play()
                print("play success")
            } catch{
                self.audioPlayer = nil
                self.videoPlayer = nil
                print(error.localizedDescription)
            }
        }
        
    }
    
    @objc fileprivate func playerItemDidReachEnd(_ notification: Notification) {
        removeFile()
        performSegue(withIdentifier: "unwindBackToRVC", sender: self)
        /*
        if self.videoPlayer != nil {
            self.videoPlayer!.seek(to: kCMTimeZero)
            self.videoPlayer!.play()
            self.audioPlayer!.play()
        }
 */
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        //dismiss(animated: true, completion: nil)
        performSegue(withIdentifier: "unwindBackToRVC", sender: self)
    }
    
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        play()
    }
    
    
    
}
