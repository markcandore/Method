//
//  DownloadService.swift
//  Method
//
//  Created by Mark Wang on 8/1/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import Foundation
import FirebaseStorage

struct DownloadService {
    
    static func downloadPreview(record: Recording, completion: @escaping (URL?) -> Void) {
        let fileName = UUID().uuidString
        
        let imageURL = record.FImageURL
        let imageRef = Storage.storage().reference(forURL: imageURL)
        let localImageURLString = (NSTemporaryDirectory() as NSString).appendingPathComponent((fileName as NSString).appendingPathExtension("png")!)
        let localImageURL = URL(fileURLWithPath: localImageURLString)
        
        let downloadImageTask = imageRef.write(toFile: localImageURL) { url, error in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return
            } else {
                return
            }
        }
        let dispatchGroup = DispatchGroup()
    
        dispatchGroup.enter()
        downloadImageTask.observe(.success) { snapshot in
            // Download completed successfully
            print("\(record.title) preview download finished")
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main){
            completion(localImageURL)
        }
    }

    static func download(record: Recording, completion: @escaping (URL?) -> Void) {
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localAudioURL = documentDirectoryURL.appendingPathComponent(record.fileID).appendingPathExtension("m4a")
        let localVideoURL = documentDirectoryURL.appendingPathComponent(record.fileID).appendingPathExtension("mov")
        
        if  !FileManager.default.fileExists(atPath: localAudioURL.absoluteString) && !FileManager.default.fileExists(atPath: localVideoURL.absoluteString){
            
            let audioURL = record.FAudioURL
            let audioRef = Storage.storage().reference(forURL: audioURL)
  
            let videoURL = record.FVideoURL
            let videoRef = Storage.storage().reference(forURL: videoURL)
    
            // Download to the local filesystem
            let dispatchGroup = DispatchGroup()
        
            dispatchGroup.enter()
            let downloadAudioTask = audioRef.write(toFile: localAudioURL) { url, error in
                if let error = error {
                    assertionFailure(error.localizedDescription)
                    return
                } else {return}
            }
            downloadAudioTask.observe(.success) { snapshot in
                // Download completed successfully
                print("\(record.title) audio download success")
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            let downloadVideoTask = videoRef.write(toFile: localVideoURL) { url, error in
                if let error = error {
                    assertionFailure(error.localizedDescription)
                    return
                } else {return}
            }

            downloadVideoTask.observe(.success) { snapshot in
                // Download completed successfully
                print("\(record.title) video download success")
                dispatchGroup.leave()
            }
            
            dispatchGroup.notify(queue: .main){
                print("\(record.title) finished downloads")
                record.localAudioURL = localAudioURL
                record.localVideoURL = localVideoURL
                
                completion(localVideoURL)
            }
        } else{
            print("\(record.title) does not download because it's been downloaded already")
            completion(record.localVideoURL)
        }
    }
}
