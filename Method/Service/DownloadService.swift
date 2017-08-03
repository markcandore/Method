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
        
        let imageURL = record.audioURL
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
    static func download(record: Recording) {
        if record.localVideoURL == nil && record.localVideoURL == nil{
            let fileName = UUID().uuidString
            
            let audioURL = record.audioURL
            let audioRef = Storage.storage().reference(forURL: audioURL)
            let localAudioURLString = (NSTemporaryDirectory() as NSString).appendingPathComponent((fileName as NSString).appendingPathExtension("m4a")!)
            let localAudioURL = URL(fileURLWithPath: localAudioURLString)
            
            let videoURL = record.videoURL
            let videoRef = Storage.storage().reference(forURL: videoURL)
            let localVideoURLString = (NSTemporaryDirectory() as NSString).appendingPathComponent((fileName as NSString).appendingPathExtension("mov")!)
            let localVideoURL = URL(fileURLWithPath: localVideoURLString)
            
            // Download to the local filesystem
            let downloadAudioTask = audioRef.write(toFile: localAudioURL) { url, error in
                if let error = error {
                    assertionFailure(error.localizedDescription)
                    return
                } else {
                    return
                }
            }
            
            let downloadVideoTask = videoRef.write(toFile: localVideoURL) { url, error in
                if let error = error {
                    assertionFailure(error.localizedDescription)
                    return
                } else {
                    return
                }
            }
            let dispatchGroup = DispatchGroup()
            
            dispatchGroup.enter()
            
            downloadAudioTask.observe(.success) { snapshot in
                // Download completed successfully
                print("\(record.title) audio download success")
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            downloadVideoTask.observe(.success) { snapshot in
                // Download completed successfully
                print("\(record.title) video download success")
                dispatchGroup.leave()
            }
            
            dispatchGroup.notify(queue: .main){
                print("finished downloads")
                record.localAudioURL = localAudioURL
                record.localVideoURL = localVideoURL
            }
        } else{
            print("\(record.title) does not download because it's been downloaded already")
        }
    }

    static func download(record: Recording, completion: @escaping (URL?) -> Void) {
        if record.localVideoURL == nil && record.localVideoURL == nil{
            let fileName = UUID().uuidString
            
            let audioURL = record.audioURL
            let audioRef = Storage.storage().reference(forURL: audioURL)
            let localAudioURLString = (NSTemporaryDirectory() as NSString).appendingPathComponent((fileName as NSString).appendingPathExtension("m4a")!)
            let localAudioURL = URL(fileURLWithPath: localAudioURLString)
            
            let videoURL = record.videoURL
            let videoRef = Storage.storage().reference(forURL: videoURL)
            let localVideoURLString = (NSTemporaryDirectory() as NSString).appendingPathComponent((fileName as NSString).appendingPathExtension("mov")!)
            let localVideoURL = URL(fileURLWithPath: localVideoURLString)
            
            // Download to the local filesystem
            let downloadAudioTask = audioRef.write(toFile: localAudioURL) { url, error in
                if let error = error {
                    assertionFailure(error.localizedDescription)
                    return
                } else {
                    return
                }
            }
            
            let downloadVideoTask = videoRef.write(toFile: localVideoURL) { url, error in
                if let error = error {
                    assertionFailure(error.localizedDescription)
                    return
                } else {
                    return
                }
            }
            let dispatchGroup = DispatchGroup()
        
            dispatchGroup.enter()
            
            downloadAudioTask.observe(.success) { snapshot in
                // Download completed successfully
                print("\(record.title) audio download success")
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            downloadVideoTask.observe(.success) { snapshot in
                // Download completed successfully
                print("\(record.title) video download success")
                dispatchGroup.leave()
            }
            
            dispatchGroup.notify(queue: .main){
                print("finished downloads")
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
