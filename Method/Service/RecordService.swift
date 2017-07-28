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
        var audioURL: String = ""
        var videoURL: String = ""
        let audioRef = StorageReference.newAudioReference()
        StorageService.uploadAudio(audioData, at: audioRef) { (downloadURL) in
            guard let downloadURL = downloadURL else {
                return
            }
            
            audioURL = downloadURL.absoluteString
        }
        
        let videoRef = StorageReference.newVideoReference()
        StorageService.uploadVideo(videoData, at: videoRef) { (downloadURL) in
            guard let downloadURL = downloadURL else {
                return
            }
            
            videoURL = downloadURL.absoluteString
        }
        
        create(forAudioURL: audioURL, forVideoURL: videoURL, forTranscript: transcriptText, forTitle: title, forTime: time)
    }



    private static func create(forAudioURL audioURL: String, forVideoURL videoURL: String, forTranscript transcriptText: String, forTitle title: String, forTime time: TimeInterval) {
        
        let currentUser = User.current
        
        let recording = Recording(audioURL: audioURL, videoURL: videoURL, title: title, transcript: transcriptText, time: time)
        let dict = recording.dictValue
        
        let rootRef = Database.database().reference()
        let recordingRef = rootRef.child("recordings").child(currentUser.uid).childByAutoId()
        //let newPostRef = DatabaseReference.toLocation(.newPost(currentUID: currentUser.uid))
        
        recordingRef.updateChildValues(dict)
        //let newPostKey = newRecordingRef.key
        
        /*
        UserService.followers(for: currentUser) { (followerUIDs) in
            let timelinePostDict = ["poster_uid" : currentUser.uid]
            
            var updatedData: [String: Any] = ["timeline/\(currentUser.uid)/\(newPostKey)" : timelinePostDict]
            
            for uid in followerUIDs {
                updatedData["timeline/\(uid)/\(newPostKey)"] = timelinePostDict
            }
            
            let postDict = post.dictValue
            updatedData["posts/\(currentUser.uid)/\(newPostKey)"] = postDict
            
            rootRef.updateChildValues(updatedData)
        }
         */
    }
    
    //private static show
}
