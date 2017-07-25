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
    
    static func create(for data: Data) {
        let audioRef = StorageReference.newAudioReference()
        StorageService.uploadAudio(data, at: audioRef) { (downloadURL) in
            guard let downloadURL = downloadURL else {
                return
            }
            
            let urlString = downloadURL.absoluteString
            //let aspectHeight = image.aspectHeight
            create(forURLString: urlString)
        }
    }
    
    private static func create(forURLString urlString: String) {
        
        let currentUser = User.current
        let recording = Recording(fileUrlString: urlString)
        
        let rootRef = Database.database().reference()
        let newRecordingRef = rootRef.child("recordings").child(currentUser.uid).childByAutoId()
        //let newPostRef = DatabaseReference.toLocation(.newPost(currentUID: currentUser.uid))
        let newPostKey = newRecordingRef.key
        
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
}
