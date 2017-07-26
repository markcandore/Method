//
//  Scoring.swift
//  Method
//
//  Created by Mark Wang on 7/26/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import Foundation
import UIKit

class Scoring {
    
    class func generalScore() -> Int{
        return 10
    }
    
    class func intelligibility(audio: Data) -> (volume: String, pitch: String, speed: String){
        let volume = "good"
        let pitch = "good"
        let speed = "good"
        
        return (volume, pitch, speed)
    }
    
    class func speakingLevel(transcript: String) -> (diction: String, structure: String){
        let diction = "good"
        let structure = "good"
        
        return (diction, structure)
    }
    
    class func automatedReadabilityIndexForString(_ string: String) -> NSDecimalNumber {
        let readability = Scoring()
        let totalWords = Float(readability.wordsInString(string as NSString))
        let totalSentences = Float(readability.sentencesInString(string as NSString))
        let totalAlphanumericCharacters = Float(readability.alphanumericCharactersInString(string))
        
        // Formula from http://en.wikipedia.org/wiki/Automated_Readability_Index
        let score = 4.71 * (totalAlphanumericCharacters / totalWords) + 0.5 * (totalWords / totalSentences) - 21.43
        
        return readability.roundFloat(score, places: 1)
    }
    
    class func colemanLiauIndexForString(_ string: String) -> NSDecimalNumber {
        let readability = Scoring()
        let totalWords = Float(readability.wordsInString(string as NSString))
        let totalSentences = Float(readability.sentencesInString(string as NSString))
        let totalAlphanumericCharacters = Float(readability.alphanumericCharactersInString(string))
        
        // Formula from http://en.wikipedia.org/wiki/Coleman–Liau_index
        let score = 5.88 * (totalAlphanumericCharacters / totalWords) - 0.296 * (totalSentences / totalWords) - 15.8
        
        return readability.roundFloat(score, places: 1)
    }
    
    class func fleschKincaidGradeLevelForString(_ string: String) -> NSDecimalNumber {
        let readability = Scoring()
        let totalWords = Float(readability.wordsInString(string as NSString))
        let totalSentences = Float(readability.sentencesInString(string as NSString))
        let alphaNumeric = readability.alphanumericString(string)
        let totalSyllables = Float(SyllableCounter.syllableCountForWords(alphaNumeric))
        
        // Formula from http://en.wikipedia.org/wiki/Flesch–Kincaid_readability_tests
        let score = 0.39 * (totalWords / totalSentences) + 11.8 * (totalSyllables / totalWords) - 15.59
        
        return readability.roundFloat(score, places: 1)
    }
    
    class func fleschReadingEaseForString(_ string: String) -> NSDecimalNumber {
        let readability = Scoring()
        let totalWords = Float(readability.wordsInString(string as NSString))
        let totalSentences = Float(readability.sentencesInString(string as NSString))
        let alphaNumeric = readability.alphanumericString(string)
        let totalSyllables = Float(SyllableCounter.syllableCountForWords(alphaNumeric))
        
        // Formula from http://en.wikipedia.org/wiki/Flesch–Kincaid_readability_tests
        let score = 206.835 - 1.015 * (totalWords / totalSentences) - 84.6 * (totalSyllables / totalWords)
        
        return readability.roundFloat(score, places: 1)
    }
    
    class func gunningFogScoreForString(_ string: String) -> NSDecimalNumber {
        let readability = Scoring()
        let totalWords = Float(readability.wordsInString(string as NSString))
        let totalSentences = Float(readability.sentencesInString(string as NSString))
        let totalComplexWords = Float(readability.complexWordsInString(string))
        
        // Formula for http://en.wikipedia.org/wiki/Gunning_fog_index
        let score = 0.4 * ( (totalWords / totalSentences) + 100 * (totalComplexWords /  totalWords) )
        
        return readability.roundFloat(score, places: 1)
    }
    
    class func smogGradeForString(_ string: String) -> NSDecimalNumber {
        let readability = Scoring()
        let totalPolysyllables = Float(readability.polysyllableWordsInString(string, excludeCommonSuffixes: false))
        let totalSentences = Float(readability.sentencesInString(string as NSString))
        
        // Formula for http://en.wikipedia.org/wiki/Gunning_fog_index
        let score = 1.043 * sqrtf(totalPolysyllables * (30 / totalSentences) + 3.1291)
        
        return readability.roundFloat(score, places: 1)
    }
    
    // MARK: Helpers
    
    func roundFloat(_ floatToRound: Float, places: Int16) -> NSDecimalNumber {
        let stringFromFloat = NSString(format: "%.13f", floatToRound)
        let decimalNumber = NSDecimalNumber(string: stringFromFloat as String)
        let decimalNumberHandler = NSDecimalNumberHandler(roundingMode: .plain, scale: places, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        let decimalNumberRounded = decimalNumber.rounding(accordingToBehavior: decimalNumberHandler)
        
        return decimalNumberRounded
    }
    
    func wordsInString(_ string: NSString) -> Int {
        let readability = Scoring()
        
        return readability.countInString(.byWords, stringToSearch: string as String)
    }
    
    func sentencesInString(_ string: NSString) -> Int {
        let readability = Scoring()
        
        return readability.countInString(.bySentences, stringToSearch: string as String)
    }
    
    func countInString(_ stringOption: NSString.EnumerationOptions, stringToSearch: String) -> Int {
        let searchRange = stringToSearch.characters.indices
        var count = 0
        
        stringToSearch.enumerateSubstrings(in: searchRange, options: stringOption) {
            substring, substringRange, enclosingRange, stop in
            count = count + 1
        }
        
        return count
    }
    
    func alphanumericCharactersInString(_ stringToCount: String) -> Int {
        let characterSet = CharacterSet.alphanumerics.inverted
        let componentsSeparated = stringToCount.components(separatedBy: characterSet)
        var count = 0
        
        for words in componentsSeparated {
            count = count + (words as NSString).length
        }
        
        return count
    }
    
    func alphanumericString(_ stringToConvert: String) -> String {
        let string = stringToConvert as NSString
        let readability = Scoring()
        let characterSet = CharacterSet.alphanumerics.inverted
        let componentsSeparated: [String] = string.components(separatedBy: characterSet)
        //let componentsSeparated: NSArray = string.components(separatedBy: characterSet)
        let componentsJoined: String = componentsSeparated.joined(separator: " ")
        //let componentsJoined: String = componentsSeparated.componentsJoined(by: " ")
        let cleaned = readability.cleanupWhiteSpace(componentsJoined as String)
        
        return readability.cleanupWhiteSpace(cleaned as String)
    }
    
    func cleanupWhiteSpace(_ stringToClean: String) -> String {
        let string = stringToClean as NSString
        let squashed: NSString = string.replacingOccurrences(of: "[ ]+", with: " ", options: .regularExpression, range: NSMakeRange(0, string.length)) as NSString
        let characterSet = CharacterSet.whitespacesAndNewlines
        let trimmed: NSString = squashed.trimmingCharacters(in: characterSet) as NSString
        
        return trimmed as String
    }
    
    func isWordPolysyllable(_ word: String, excludeCommonSuffixes: Bool) -> Bool {
        var polysyllable = false
        
        if SyllableCounter.syllableCountForWord(word) > 2 {
            
            if excludeCommonSuffixes {
                
                if !word.lowercased().hasSuffix("es") && !word.lowercased().hasSuffix("ed") && !word.lowercased().hasSuffix("ing") {
                    polysyllable = true
                }
                
            } else {
                polysyllable = true
            }
            
        }
        
        return polysyllable
    }
    
    func polysyllableWordsInString(_ stringToCount: String, excludeCommonSuffixes: Bool) -> Int {
        let readability = Scoring()
        let searchRange = stringToCount.characters.indices
        var count = 0
        
        stringToCount.enumerateSubstrings(in: searchRange, options: .byWords) {
            substring, substringRange, enclosingRange, stop in
            
            if readability.isWordPolysyllable(substring!, excludeCommonSuffixes: excludeCommonSuffixes) {
                count = count + 1
            }
        }
        
        return count
    }
    
    func isWordCapitalized(_ word: String) -> Bool {
        let characterSet = CharacterSet.uppercaseLetters
        let firstCharacter = (word as NSString).character(at: 0)
        
        return characterSet.contains(UnicodeScalar(firstCharacter)!)
    }
    
    func complexWordsInString(_ stringToCount: String) -> Int {
        let readability = Scoring()
        let searchRange = stringToCount.characters.indices
        //let searchRange = stringToCount.characters.
        var count = 0
        
        stringToCount.enumerateSubstrings(in: searchRange, options: .byWords) {
            substring, substringRange, enclosingRange, stop in
            
            // Attemping the complex word suggestions at http://en.wikipedia.org/wiki/Gunning_fog_index
            let polysyllable = readability.isWordPolysyllable(substring!, excludeCommonSuffixes: true)
            let properNoun = readability.isWordCapitalized(substring!)
            let familiarJargon = false // TODO
            let compound = false // TODO
            
            if polysyllable && !properNoun && !familiarJargon && !compound {
                count = count + 1
            }
            
        }
        
        return count
    }
    
}

