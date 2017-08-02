//
//  Note.swift
//  Method
//
//  Created by Mark Wang on 8/1/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import Foundation

enum Accidental: String {
    case Sharp = "♯"
    case Flat  = "♭"
}

enum Note: CustomStringConvertible{
    case c(_: Accidental?)
    case d(_: Accidental?)
    case e(_: Accidental?)
    case f(_: Accidental?)
    case g(_: Accidental?)
    case a(_: Accidental?)
    case b(_: Accidental?)
    
    /**
     * This array contains all notes.
     */
    static let all: [Note] = [
        c(nil),   c(.Sharp),
        d(nil),
        e(.Flat), e(nil),
        f(nil),   f(.Sharp),
        g(nil),
        a(.Flat), a(nil),
        b(.Flat), b(nil)
    ]
    
    /**
     * This function returns the frequency of this note in the 4th octave.
     */
    
    var frequency: Double {
        let index = Note.all.index(where: { $0 == self   })! -
            Note.all.index(where: { $0 == Note.a(nil) })!
        
        return 440 * pow(2, Double(index) / 12.0)
    }
    
    
    var description: String {
        let concat = { (letter: String, accidental: Accidental?) in
            return letter + (accidental != nil ? accidental!.rawValue : "")
        }
        
        switch self {
        case let .c(a): return concat("C", a)
        case let .d(a): return concat("D", a)
        case let .e(a): return concat("E", a)
        case let .f(a): return concat("F", a)
        case let .g(a): return concat("G", a)
        case let .a(a): return concat("A", a)
        case let .b(a): return concat("B", a)
        }
    }
}

func ==(a: Note, b: Note) -> Bool {
    return a.description == b.description
}
