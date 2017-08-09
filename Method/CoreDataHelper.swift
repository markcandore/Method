//
//  CoreDataHelper.swift
//  Method
//
//  Created by Mark Wang on 8/6/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class CoreDataHelper {
    static let appDelegate = UIApplication.shared.delegate as! AppDelegate
    static let persistentContainer = appDelegate.persistentContainer
    static let managedContext = persistentContainer.viewContext
    //static methods will go here
    
    static func newRecording() -> Recording{
        let recording = NSEntityDescription.insertNewObject(forEntityName: "Recording", into: managedContext) as! Recording
        return recording
    }
    
    static func saveRecording(){
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save \(error)")
        }
    }
    
    static func delete(recording: Recording){
        managedContext.delete(recording)
        saveRecording()
    }
    
    static func retrieveRecordings() -> [Recording] {
        let fetchRequest = NSFetchRequest<Recording>(entityName: "Recording")
        do {
            let results = try managedContext.fetch(fetchRequest)
            return results
        } catch let error as NSError {
            print("Could not fetch \(error)")
        }
        return []
    }
}
