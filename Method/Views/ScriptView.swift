//
//  ScriptView.swift
//  Method
//
//  Created by Mark Wang on 8/3/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import Foundation
import UIKit

class ScriptView: UITextView{
   
    init(frame: CGRect) {
        let size = CGSize(width: 50, height: 50)
        let container = NSTextContainer(size: size)
        super.init(frame: frame, textContainer: container)
        self.textColor = UIColor.white
        self.backgroundColor = UIColor.black
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
