//
//  Script.swift
//  Method
//
//  Created by Mark Wang on 8/3/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Script {
    var sentence: String
    init(json: JSON) {
        let count = json.count
     
        let random = arc4random_uniform(UInt32(count)) + 1
        let line = json[Int(random)].stringValue
        self.sentence = ""
        setSentence(line: line)
    }

    mutating func setSentence(line: String){
        self.sentence = line
    }
    
    func getQuote() -> String{
        
        return ""
    }
    
    func getTitle() -> String{
        return ""
    }
}
