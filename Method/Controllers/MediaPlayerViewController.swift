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
import Photos

//import AudioKit
import FirebaseStorage
class MediaPlayerViewController: UIViewController , AVPlayerViewControllerDelegate, UIGestureRecognizerDelegate{

    var volume = 1.0
    //var record: Recording!
    var audioPlayer: AVAudioPlayer!
    var videoPlayer: AVPlayer!
    var playerController : AVPlayerViewController?
    var url: URL!
    var item: AVPlayerItem!
    var transcriptText: String?
    
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
    func tap(){
        let topView = UIView.init(frame: self.view.frame)
        topView.backgroundColor = .clear
        self.view.addSubview(topView)
        
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapGesture(tap:)))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.delegate = self
        topView.addGestureRecognizer(singleTapGesture)
    }
    
    func transcript(){
        let height = self.view.frame.height/2.0 + self.view.frame.height/4.0
        let frame = CGRect(x: 0, y: height, width: self.view.frame.width, height: self.view.frame.height/4.0)
        let scriptView = UITextView(frame: frame )
       
        scriptView.backgroundColor = .clear
        scriptView.text = transcriptText
        scriptView.textColor = UIColor.white
      
        scriptView.font = scriptView.font?.withSize(40)
        self.view.addSubview(scriptView)
        
    }
    
    func play(){
        print("play")
        if self.url != nil
        {
            do{
                //important line below
                AudioSessionCommandHelper.setAudioSessionCategoryPlayback()
                
                
                self.videoPlayer = AVPlayer(url: url)
                
                self.playerController = AVPlayerViewController()
                self.playerController!.showsPlaybackControls = false
                self.playerController!.player = self.videoPlayer
                
                self.addChildViewController(self.playerController!)
                self.view.addSubview(self.playerController!.view)
                
                self.playerController!.view.frame = self.view.frame
                NotificationCenter.default.addObserver(self, selector: #selector(self.playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.videoPlayer!.currentItem)
                
                self.transcript()
                self.tap()
                self.videoPlayer?.play()
                print("play success")
            } catch{
                self.videoPlayer = nil
                print(error.localizedDescription)
            }

        } else{
            print("file does not exist")
        }
    }
    
    /*
    func play(){
        print("try play")
        if self.item != nil{
            DispatchQueue.main.async(execute: {
                
                if self.item.asset.isPlayable{
                    //self.videoPlayer = AVPlayer(playerItem: self.item)
                    let playerViewController = AVPlayerViewController()
                    playerViewController.delegate = self
                    playerViewController.player = self.videoPlayer
                    
                    playerViewController.showsPlaybackControls = false
                    playerViewController.view.frame = self.view.frame
                    NotificationCenter.default.addObserver(self, selector: #selector(self.playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.videoPlayer!.currentItem)
                    
                    self.view.addSubview(playerViewController.view)
                    self.tap()
                    
                    self.videoPlayer.seek(to: kCMTimeZero)
                    playerViewController.player!.play()
                    
                } else{
                    print("not playable")
                }
            })
        } else{
            print("files do not exist")
        }
    }
    */
    
    /*
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
                //self.audioPlayer.play()
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
    */
    @objc fileprivate func playerItemDidReachEnd(_ notification: Notification) {
        //performSegue(withIdentifier: "unwindBackToRVC", sender: self)
        
        if self.videoPlayer != nil {
            self.videoPlayer!.seek(to: kCMTimeZero)
            self.videoPlayer!.play()
            //self.audioPlayer!.play()
        }
 
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "unwindBackToRVC", sender: self)
    }
    
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        play()
    }
    
    @objc fileprivate func singleTapGesture(tap: UITapGestureRecognizer) {
        self.videoPlayer?.pause()
        performSegue(withIdentifier: "unwindBackToRVC", sender: self)
    }
}

