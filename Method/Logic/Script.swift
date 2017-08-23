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
     
        let random = arc4random_uniform(UInt32(count)) 
        let line = json[Int(random)].stringValue
        self.sentence = ""
        setSentence(line: line)
    }

    mutating func setSentence(line: String){
        self.sentence = line
    }
    
    func getQuote() -> String{
        let components = sentence.components(separatedBy: "\"")
        let quote = components.dropFirst().first
        return quote!
    }
    
    func getTitle() -> String{

        let removedFirst = sentence.characters.dropFirst()
        let index = removedFirst.index(of: "\"")
        if index != nil{
            let index2 = removedFirst.index(index!, offsetBy: 2)
            let title = sentence.substring(from: index2)
            return title
        } else{
            print(sentence)
            return "NONE"
        }
        //return "NONE"
    }
    
    func getTitle(sentence: String) -> String{
        
        let removedFirst = sentence.characters.dropFirst()
        let index = removedFirst.index(of: "\"")
        
        let index2 = removedFirst.index(index!, offsetBy: 2)
        
        let title = sentence.substring(from: index2)
        return title
    }
    
    
}
