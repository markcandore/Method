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
    
    var fileData: Data?
    
    init(fileUrlString: String){
        self.fileUrlString = fileUrlString
        self.creationDate = Date()
        self.creator = User.current
    }
    
    init(data: Data){
        self.fileData = data
        self.creationDate = Date()
        self.creator = User.current
    }
    
}
