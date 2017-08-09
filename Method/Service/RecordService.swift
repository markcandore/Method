//
//  RecordService.swift
//  Method
//
//  Created by Mark Wang on 7/24/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import Foundation
import FirebaseStorage
import FirebaseDatabase
import UIKit
import Photos
struct RecordService {
    static func getAlbumWithName(name: String, completion: @escaping (_ album: PHAssetCollection?) -> Void) {
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localizedTitle = %@", name)
        let fetchResult = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.any, options: fetchOptions)
        
        if fetchResult.count > 0 {
            
            guard let album = fetchResult.firstObject else {return}
            completion(album)
            
        } else {
            
            PHPhotoLibrary.shared().performChanges({
                
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
                
            }, completionHandler: { (result, error) in
                if result {
                    print("created album")
                    getAlbumWithName(name: name, completion: completion)
                } else {
                    completion(nil)
                }
            })
        }
    }
    
    /** Adds an video to the specified album */
    static func addVideo(toUrl url: URL, toAlbum album: PHAssetCollection, completion: ((_ status: Bool) -> Void)?) {
        
        PHPhotoLibrary.shared().performChanges({
            
            let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            let assetPlaceholder = assetRequest?.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            let enumeration: NSArray = [assetPlaceholder!]
            albumChangeRequest?.addAssets(enumeration)
            print("video added")
            
        }) { saved, error in
            if saved {
                print("local temp clear")
                FileManager.default.clearTmpDirectory()
                /*
                 let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                 let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                 alertController.addAction(defaultAction)
                 self.present(alertController, animated: true, completion: nil)
                 */
            }
        }
    }
/*
    static func create(audioData: Data, videoData: Data, transcriptText: String,title: String, fileID : String,duration: TimeInterval, score: Double, preview: UIImage) {
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        var audioURL: String = ""
        let audioRef = StorageReference.newAudioReference()
        StorageService.uploadAudio(audioData, at: audioRef) { (downloadURL) in
            defer {
                dispatchGroup.leave()
            }
            guard let downloadURL = downloadURL else {
                return
            }
            audioURL = downloadURL.absoluteString
        }
        
        dispatchGroup.enter()
        var videoURL: String = ""
        let videoRef = StorageReference.newVideoReference()
        StorageService.uploadVideo(videoData, at: videoRef) { (downloadURL) in
            defer {
                dispatchGroup.leave()
            }
            guard let downloadURL = downloadURL else {
                return
            }
            videoURL = downloadURL.absoluteString
        }
        
        dispatchGroup.enter()
        var imageURL: String = ""
        let imageRef = StorageReference.newImageReference()
        let imageData = UIImagePNGRepresentation(preview) as Data!
        StorageService.uploadPreview(imageData, at: imageRef) { (downloadURL) in
            defer {
                dispatchGroup.leave()
            }
            guard let downloadURL = downloadURL else {
                return
            }
            imageURL = downloadURL.absoluteString
        }
        
        dispatchGroup.notify(queue: .main) {
            print("uploaded to storage")
            addToDatabase(forAudioURL: audioURL, forVideoURL: videoURL, forPreviewURL: imageURL, forTranscript: transcriptText, forTitle: title, forFileID: fileID,forTime: duration)
        }
    }

    private static func addToDatabase(forAudioURL audioURL: String, forVideoURL videoURL: String, forPreviewURL imageURL: String, forTranscript transcriptText: String, forTitle title: String, forFileID fileID: String,forTime time: TimeInterval) {
        
        let currentUser = User.current
        
        let recording = Recording(audioURL: audioURL, videoURL: videoURL, imageURL: imageURL, fileID: fileID, title: title,transcript: transcriptText, duration: time)
        let dict = recording.dictValue
        
        let rootRef = Database.database().reference()
        let recordingRef = rootRef.child("recordings").child(currentUser.uid).childByAutoId()
        recordingRef.updateChildValues(dict)
        print("uploaded to database")
    }
    
    static func delete(record: Recording) {
        
        let currentUser = User.current
        
        let recordKey = record.key
        let databaseRef = Database.database().reference().child("recordings").child(currentUser.uid).child(recordKey!)
        
        databaseRef.removeValue()
        
        let audioURL = record.FAudioURL
        let videoURL = record.FVideoURL
        let imageURL = record.FImageURL
        
        StorageService.deleteFiles(audioURL: audioURL, videoURL: videoURL, imageURL: imageURL)
        
    }
 */
}

