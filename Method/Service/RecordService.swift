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
    
    static func create(data: Data, title: String) {
        let audioRef = StorageReference.newRecordingReference()
        StorageService.uploadAudio(data, at: audioRef) { (downloadURL) in
            guard let downloadURL = downloadURL else {
                return
            }
            
            let urlString = downloadURL.absoluteString
            //let aspectHeight = image.aspectHeight
            create(forURLString: urlString, forTitle: title)
        }
    }
    
    private static func create(forURLString urlString: String, forTitle title: String) {
        
        let currentUser = User.current
        //let recording = Recording(fileUrlString: urlString)
        let recording = Recording(fileUrlString: urlString, title: title)
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
