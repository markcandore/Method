//
//  Recording.swift
//  Method
//
//  Created by Mark Wang on 7/20/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import Foundation
import FirebaseDatabase.FIRDataSnapshot
import AVFoundation

class Recording{
    var key: String?
    var title: String
    var transcript: String
    var audioURL: String
    var videoURL: String
    var creationDate: Date
    var creator: User
    var duration: TimeInterval
    
    var localAudioURL: URL?
    var localVideoURL: URL?
    
    let timestampFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        return dateFormatter
    }()
    
    init(audioURL: String, videoURL: String, title: String, transcript: String, duration: TimeInterval){
        self.title = title
        self.transcript = transcript
        self.duration = duration
        self.audioURL = audioURL
        self.videoURL = videoURL
        self.creationDate = Date()
        self.creator = User.current
    }
    
    init?(snapshot: DataSnapshot) {
        guard let dict = snapshot.value as? [String : Any],
            let audioURL = dict["audio_url"] as? String,
            let videoURL = dict["video_url"] as? String,
            let audioTitle = dict["title"] as? String,
            let transcriptText = dict["transcript"] as? String,
            let createdAgo = dict["created_at"] as? TimeInterval,
            let duration = dict["duration"] as? TimeInterval,
            let userDict = dict["creator"] as? [String : Any],
            let uid = userDict["uid"] as? String,
            let username = userDict["username"] as? String
        
            else { return nil }
        
        self.key = snapshot.key
        self.title = audioTitle
        self.transcript = transcriptText
        self.audioURL = audioURL
        self.videoURL = videoURL
        self.creationDate = Date(timeIntervalSince1970: createdAgo)
        self.duration = duration
        self.creator = User(uid: uid, username: username)
        
    }
    
    var dictValue: [String : Any] {
        let createdAgo = creationDate.timeIntervalSince1970
        let userDict = ["uid" : creator.uid,
                        "username" : creator.username]
        
        return ["audio_url" : audioURL,
                "video_url" : videoURL,
                "title" : title,
                "transcript" : transcript,
                "created_at" : createdAgo,
                "duration" : duration,
                "creator" : userDict]
    }
    
    func getDateString() -> String{
        return timestampFormatter.string(from: self.creationDate)
    }
    
}
