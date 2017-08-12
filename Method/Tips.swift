//
//  Tips.swift
//  Method
//
//  Created by Mark Wang on 8/12/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import Foundation

struct Tips{
    
    var tip: String
    
    init() {
        tip = ""
        setTip()
    }
    
    mutating func setTip(){
        let random = arc4random_uniform(UInt32(6))
        switch random{
        case 0:
        self.tip = "Broaden your mouth when talking"
        break
        case 1:
        self.tip = "Speak from diaphragm"
        break
        case 2:
        self.tip = "Speak with more confidence"
        break
        case 3:
        self.tip = "Relax the jaw, lips, and throat"
        break
        case 4:
        self.tip = "Imagine you’re a bubblehead; stretches and elongates the entire throat "
        break
        case 5:
        self.tip = "Use cheeks more than the lip"
        break
        default:
        self.tip = ""
        break
        }
    }
    
}
