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

struct RecordService {


    static func create(audioData: Data, videoData: Data, transcriptText: String,title: String, time: TimeInterval) {
        
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
        
        dispatchGroup.notify(queue: .main) { 
            create(forAudioURL: audioURL, forVideoURL: videoURL, forTranscript: transcriptText, forTitle: title, forTime: time)
        }
    }



    private static func create(forAudioURL audioURL: String, forVideoURL videoURL: String, forTranscript transcriptText: String, forTitle title: String, forTime time: TimeInterval) {
        
        let currentUser = User.current
        
        let recording = Recording(audioURL: audioURL, videoURL: videoURL, title: title, transcript: transcriptText, time: time)
        let dict = recording.dictValue
        
        let rootRef = Database.database().reference()
        let recordingRef = rootRef.child("recordings").child(currentUser.uid).childByAutoId()
        recordingRef.updateChildValues(dict)
    }
    
    static func delete(record: Recording) {
        
        let currentUser = User.current
        
        let recordKey = record.key
        
        let databaseRef = Database.database().reference().child("recordings").child(currentUser.uid).child(recordKey!)
        
        databaseRef.removeValue()
        
        let audioURL = record.audioURL
        let videoURL = record.videoURL
        
        StorageService.deleteFiles(audioURL: audioURL, videoURL: videoURL)
    }
    
    
}
