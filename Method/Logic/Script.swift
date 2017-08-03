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
    let quote: String?
    let title: String?
    init(json: JSON) {
        let count = json.count
        //let lines =  json[]
        
        let random = arc4random_uniform(UInt32(count)) + 1
        let line = json[Int(random)].stringValue
        self.quote = ""
        self.title = ""
        //quote = setQuote(line: line)
        //title = setTitle(line: line)
        setQuote(line: line)
        setTitle(line: line)
    }
    
    private func setQuote(line: String){
        
    }
    
    private func setTitle(line: String){
        
    }
    
}
