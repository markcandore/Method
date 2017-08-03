//
//  RecordService.swift
//  Method
//
//  Created by Mark Wang on 7/24/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import Foundation
import FirebaseStorage
import FirebaseDatabase
import UIKit
struct RecordService {


    static func create(audioData: Data, videoData: Data, transcriptText: String,title: String, duration: TimeInterval, preview: UIImage) {
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        var audioURL: String = ""
        let audioRef = StorageReference.newAudioReference()
        StorageService.uploadAudio(audioData, at: audioRef) { (downloadURL) in
            defer {
                dispatchGroup.leave()
            }
            guard let downloadURL = downloadURL else {
                return
            }
            audioURL = downloadURL.absoluteString
        }
        
        dispatchGroup.enter()
        var videoURL: String = ""
        let videoRef = StorageReference.newVideoReference()
        StorageService.uploadVideo(videoData, at: videoRef) { (downloadURL) in
            defer {
                dispatchGroup.leave()
            }
            guard let downloadURL = downloadURL else {
                return
            }
            videoURL = downloadURL.absoluteString
        }
        
        dispatchGroup.enter()
        var imageURL: String = ""
        let imageRef = StorageReference.newImageReference()
        let imageData = UIImagePNGRepresentation(preview) as Data!
        StorageService.uploadPreview(imageData, at: imageRef) { (downloadURL) in
            defer {
                dispatchGroup.leave()
            }
            guard let downloadURL = downloadURL else {
                return
            }
            imageURL = downloadURL.absoluteString
        }
        
        dispatchGroup.notify(queue: .main) {
            print("uploaded to storage")
            create(forAudioURL: audioURL, forVideoURL: videoURL, forPreviewURL: imageURL, forTranscript: transcriptText, forTitle: title, forTime: duration)
        }
    }

    private static func create(forAudioURL audioURL: String, forVideoURL videoURL: String, forPreviewURL imageURL: String, forTranscript transcriptText: String, forTitle title: String, forTime time: TimeInterval) {
        
        let currentUser = User.current
        
        let recording = Recording(audioURL: audioURL, videoURL: videoURL, imageURL: imageURL, title: title, transcript: transcriptText, duration: time)
        let dict = recording.dictValue
        
        let rootRef = Database.database().reference()
        let recordingRef = rootRef.child("recordings").child(currentUser.uid).childByAutoId()
        recordingRef.updateChildValues(dict)
        print("uploaded to database")
    }
    
    static func delete(record: Recording) {
        
        let currentUser = User.current
        
        let recordKey = record.key
        
        let databaseRef = Database.database().reference().child("recordings").child(currentUser.uid).child(recordKey!)
        
        databaseRef.removeValue()
        
        let audioURL = record.audioURL
        let videoURL = record.videoURL
        let imageURL = record.imageURL
        
        StorageService.deleteFiles(audioURL: audioURL, videoURL: videoURL, imageURL: imageURL)
    }
    
    
}
