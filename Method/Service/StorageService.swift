//
//  StorageService.swift
//  Method
//
//  Created by Mark Wang on 7/20/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import Foundation
import FirebaseStorage
import UIKit

struct StorageService {
 
    static func uploadAudio(_ audioData: Data?, at reference: StorageReference, completion: @escaping (URL?) -> Void) {
        guard let audio = audioData else{
            return completion(nil)
        }
        
        reference.putData(audio, metadata: nil, completion: { (metadata, error) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return completion(nil)
            }

            completion(metadata?.downloadURL())
        })
    }
    
    static func uploadVideo(_ videoData: Data?, at reference: StorageReference, completion: @escaping (URL?) -> Void) {
        guard let video = videoData else{
            return completion(nil)
        }
        
        reference.putData(video, metadata: nil, completion: { (metadata, error) in
            if let error = error {
                assertionFailure(error.localizedDescription)
                return completion(nil)
            }
            
            completion(metadata?.downloadURL())
        })
    }
    
    static func deleteFiles(audioURL: String, videoURL: String){
        let audioRef = Storage.storage().reference(forURL: audioURL)
        let videoRef = Storage.storage().reference(forURL: videoURL)

        audioRef.delete()
        videoRef.delete()
    }
 

}
