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
    var title: String?
    var fileUrlString: String?
    var creationDate: Date
    var creator: User
    
    let timestampFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        return dateFormatter
    }()
    
    init(fileUrlString: String){
        self.fileUrlString = fileUrlString
        self.creationDate = Date()
        self.creator = User.current
    }
    
    init?(snapshot: DataSnapshot) {
        guard let dict = snapshot.value as? [String : Any],
            let audioURL = dict["image_url"] as? String,
            let audioTitle = dict["title"] as? String,
            let userDict = dict["creator"] as? [String : Any],
            let uid = userDict["uid"] as? String,
            let username = userDict["username"] as? String
            else { return nil }
        
        self.key = snapshot.key
        self.title = audioTitle
        self.fileUrlString = audioURL
        self.creationDate = Date()
        self.creator = User(uid: uid, username: username)
        
    }
    
    func getDateString() -> String{
        return timestampFormatter.string(from: self.creationDate)
    }
    
}
