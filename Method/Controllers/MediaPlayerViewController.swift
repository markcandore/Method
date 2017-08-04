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
//import AudioKit
import FirebaseStorage
class MediaPlayerViewController: UIViewController {

    var volume = 1.0
    var record: Recording!
    var audioPlayer: AVAudioPlayer!
    var videoPlayer: AVPlayer?
    var playerController : AVPlayerViewController?

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var transcriptTextView: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.play()
        /*
        DownloadService.download(record: record){ (vidURL) in
         
            guard let url = vidURL else{
                return
            }
            guard let image = ImageCaptureHelper.videoPreviewUiimage(vidURL: url) else{
                return
            }
            let previewView = UIView(frame: self.view.frame)
            previewView.backgroundColor = UIColor(patternImage: image)
            super.view.addSubview(previewView)

            self.play()
        }
        */
    }
  
    func removeFile(){
        do{
            try FileManager.default.removeItem(atPath: (record?.localAudioURL?.absoluteString)!)
            try FileManager.default.removeItem(atPath: (record?.localVideoURL?.absoluteString)!)
        } catch{
            print(error)
        }
    }
    func tap(){
        let topView = UIView.init(frame: self.view.frame)
        topView.backgroundColor = .clear
        self.view.addSubview(topView)
        
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapGesture(tap:)))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.delegate = self
        topView.addGestureRecognizer(singleTapGesture)
    }
    
    func play(){
        print("play")
        if (record.localVideoURL != nil && record.localAudioURL != nil){
            do{
                AudioSessionCommandHelper.setAudioSessionCategoryPlayback()
                
                self.audioPlayer = try AVAudioPlayer(contentsOf: (record?.localAudioURL)!)
                self.videoPlayer = AVPlayer(url: (record?.localVideoURL)!)
                
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
                
                self.tap()
                self.audioPlayer.play()
                self.videoPlayer?.play()
                print("play success")
            } catch{
                self.audioPlayer = nil
                self.videoPlayer = nil
                print(error.localizedDescription)
            }
        } else{
            print("files do not exist")
        }
    }
    
    @objc fileprivate func playerItemDidReachEnd(_ notification: Notification) {
        //performSegue(withIdentifier: "unwindBackToRVC", sender: self)
        
        if self.videoPlayer != nil {
            self.videoPlayer!.seek(to: kCMTimeZero)
            self.videoPlayer!.play()
            self.audioPlayer!.play()
        }
 
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "unwindBackToRVC", sender: self)
    }
    
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        play()
    }
    
    @objc fileprivate func singleTapGesture(tap: UITapGestureRecognizer) {
        performSegue(withIdentifier: "unwindBackToRVC", sender: self)
    }
}

extension MediaPlayerViewController: UIGestureRecognizerDelegate{
    
}
