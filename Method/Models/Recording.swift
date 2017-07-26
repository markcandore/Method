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
    var fileUrlString: String
    var creationDate: Date
    var creator: User
    var time: TimeInterval
    
    let timestampFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        return dateFormatter
    }()
    
    init(fileUrlString: String, title: String, transcript: String, time: TimeInterval){
        self.title = title
        self.transcript = transcript
        self.time = time
        self.fileUrlString = fileUrlString
        self.creationDate = Date()
        self.creator = User.current
    }
    
    init?(snapshot: DataSnapshot) {
        guard let dict = snapshot.value as? [String : Any],
            let audioURL = dict["audio_url"] as? String,
            let audioTitle = dict["title"] as? String,
            let transcriptText = dict["transcript"] as? String,
            let createdAgo = dict["created_at"] as? TimeInterval,
            let time = dict["time"] as? TimeInterval,
            let userDict = dict["creator"] as? [String : Any],
            let uid = userDict["uid"] as? String,
            let username = userDict["username"] as? String
        
            else { return nil }
        
        self.key = snapshot.key
        self.title = audioTitle
        self.transcript = transcriptText
        self.fileUrlString = audioURL
        self.creationDate = Date(timeIntervalSince1970: createdAgo)
        self.time = time
        self.creator = User(uid: uid, username: username)
        
    }
    
    var dictValue: [String : Any] {
        let createdAgo = creationDate.timeIntervalSince1970
        let userDict = ["uid" : creator.uid,
                        "username" : creator.username]
        
        return ["audio_url" : fileUrlString,
                "title" : title,
                "transcript" : transcript,
                "created_at" : createdAgo,
                "time" : time,
                "creator" : userDict]
    }
    
    func getDateString() -> String{
        return timestampFormatter.string(from: self.creationDate)
    }
    
}
