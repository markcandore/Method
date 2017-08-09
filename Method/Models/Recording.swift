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
/*
class Recording{
    var key: String?
    var title: String
    var transcript: String
    var FAudioURL: String
    var FVideoURL: String
    var FImageURL: String
    var creationDate: Date
    var creator: User
    var duration: TimeInterval
    var fileID: String
    var localAudioURL: URL?
    var localVideoURL: URL?
    
    let timestampFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        return dateFormatter
    }()
    
    init(audioURL: String, videoURL: String, imageURL: String, fileID: String, title: String, transcript: String, duration: TimeInterval){
        //let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.title = title
        self.transcript = transcript
        self.duration = duration
        self.FAudioURL = audioURL
        self.FVideoURL = videoURL
        self.FImageURL = imageURL
        self.fileID = fileID
        //self.localAudioURL = documentDirectoryURL.appendingPathComponent(fileID).appendingPathExtension("m4a")
        //self.localVideoURL = documentDirectoryURL.appendingPathComponent(fileID).appendingPathExtension("mov")
        self.creationDate = Date()
        self.creator = User.current
    }
    
    init?(snapshot: DataSnapshot) {
        guard let dict = snapshot.value as? [String : Any],
            let FAudioURL = dict["Faudio_url"] as? String,
            let FVideoURL = dict["Fvideo_url"] as? String,
            let FImageURL = dict["Fimage_url"] as? String,
            let fileID = dict["file_id"] as? String,
           // let localAudioURL = dict["local_audio_url"] as? URL,
            //let localVideoURL = dict["local_video_url"] as? URL,
            let title = dict["title"] as? String,
            let transcriptText = dict["transcript"] as? String,
            let createdAgo = dict["created_at"] as? TimeInterval,
            let duration = dict["duration"] as? TimeInterval,
            let userDict = dict["creator"] as? [String : Any],
            let uid = userDict["uid"] as? String,
            let username = userDict["username"] as? String
        
            else { return nil }
        
        self.key = snapshot.key
        self.title = title
        self.transcript = transcriptText
        self.FAudioURL = FAudioURL
        self.FVideoURL = FVideoURL
        self.FImageURL = FImageURL
        self.fileID = fileID
        //self.localAudioURL = localAudioURL
        //self.localVideoURL = localVideoURL
        self.creationDate = Date(timeIntervalSince1970: createdAgo)
        self.duration = duration
        self.creator = User(uid: uid, username: username)
        
    }
    
    var dictValue: [String : Any] {
        let createdAgo = creationDate.timeIntervalSince1970
        let userDict = ["uid" : creator.uid,
                        "username" : creator.username]
        
        return ["Faudio_url" : FAudioURL,
                "Fvideo_url" : FVideoURL,
                "Fimage_url" : FImageURL,
                "file_id" : fileID,
                //"local_audio_url" : localAudioURL,
                //"local_video_url" : localVideoURL,
                "title" : title,
                "transcript" : transcript,
                "created_at" : createdAgo,
                "duration" : duration,
                "creator" : userDict]
    }
    
    func getDateString() -> String{
        return timestampFormatter.string(from: self.creationDate)
    }
    
    func getTimeString() -> String{
        let format = DateFormatter()
        //format.dateFormat = "MMM d, YYYY h:mm a"
        format.dateFormat = "MM/dd/yyyy h:mm a"
        let time = format.string(from: self.creationDate)
        return time
    }
}
*/
