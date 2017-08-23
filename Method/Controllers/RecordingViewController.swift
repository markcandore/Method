/* Credits:
 
video implementation
Copyright (c) 2016, Andrew Walz.
 
*/
//  RecordingViewController.swift
//  Method
//
//  Created by Mark Wang on 7/19/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import UIKit
import Speech
import AVFoundation
import AVKit
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth
import SwiftyJSON
import Photos

class RecordingViewController: UIViewController, UIGestureRecognizerDelegate ,SFSpeechRecognizerDelegate, AVAudioRecorderDelegate, PHPhotoLibraryChangeObserver{

    
    // MARK: Properties
    /*
    let tuner       = Tuner()
    let displayView = DisplayView()
    */
    var isRecording = false
    // Timer
    var countdownTime = 30.0 - (2*0.68181818181)
    var countdownTimer = Timer()
    var isTimerRunning = false
    
    var countingTimer = Timer()
    var recordingTime = 0.0
    var finalTime = 0.0
    var countdownImage = -1
    
    var articulationScore = 0.0
    //Speech Recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    //Audio
    private var audioRecorder: AVAudioRecorder!
    var soundFileURL:URL!
    var currentFilename: String!
    //var currentRecording: Recording!
    
    //UI Elements
    @IBOutlet weak var listTableView: UITableView!
    @IBOutlet weak var transcriptTextView: UITextView!
    @IBOutlet weak var scriptTextView: UITextView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var countingTimerLabel: UILabel!
   
    //Video Setup
    
    fileprivate enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private var videoQuality: VideoQuality = .medium
    private var videoGravity: VideoGravity = .resizeAspect
    private var camera: CameraSelection = .front
    private var videoSession = AVCaptureSession()

    var audioEnabled = true
    //var isVideoRecording = false
    var isSessionRunning = false
    var lowLightBoost = true
    var shouldUseDeviceOrientation = false
    
    fileprivate let sessionQueue = DispatchQueue(label: "session queue", attributes: [])
    
    fileprivate var setupResult = SessionSetupResult.success
    fileprivate var backgroundRecordingID: UIBackgroundTaskIdentifier? = nil
    fileprivate var videoDeviceInput : AVCaptureDeviceInput!
    fileprivate var movieFileOutput : AVCaptureMovieFileOutput?
    fileprivate var videoDevice : AVCaptureDevice?
    fileprivate var previewLayer: PreviewView!
    fileprivate var deviceOrientation : UIDeviceOrientation?
    
    //var videoOutputFilePath: String!
    //var audioOutputFilePath: String!
    var uniqueID: String!
    var recordings = [Recording]()
    var recordingPreviews = [UIImage?](){
        didSet{
            listTableView.reloadData()
        }
    }
    
    var fetchResult : PHFetchResult<PHAsset>!
    let avplayer = AVPlayer()
    var phAssets = [PHAsset]()
    var videoManager: PHCachingImageManager?
    
    var isQuoteToggled = false
    
    func configureTableView() {
        listTableView.dataSource = self
        listTableView.tableFooterView = UIView()
        listTableView.separatorStyle = .none
        listTableView.isHidden = true
        
    }
    
    /*
    func tunerDidMeasurePitch(_ pitch: Pitch, withDistance distance: Double,
                              amplitude: Double) {
        /* Scale the amplitude to make it look more dramatic. */
        displayView.amplitude = min(1.0, amplitude * 25.0)
        displayView.frequency = pitch.frequency
        
        if amplitude < 0.01 {
            return
        }
    }
    */
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Change notifications may be made on a background queue.
        // Re-dispatch to the main queue to update the UI.
        DispatchQueue.main.sync {
            print("photo library changes")
           
            /*
            // Check for changes to the displayed album itself
            // (its existence and metadata, not its member assets).
            if let albumChanges = changeInstance.changeDetails(for: assetCollection) {
                // Fetch the new album and update the UI accordingly.
                assetCollection = albumChanges.objectAfterChanges! as! PHAssetCollection
                navigationController?.navigationItem.title = assetCollection.localizedTitle
            }
 */
            /*
            // Check for changes to the list of assets (insertions, deletions, moves, or updates).
            if let changes = changeInstance.changeDetails(for: fetchResult) {
                // Keep the new fetch result for future use.
                fetchResult = changes.fetchResultAfterChanges
                if changes.hasIncrementalChanges {
                    // If there are incremental diffs, animate them in the collection view.
                    print("list changes")
                    /*
                    if let removed = changes.removedIndexes, removed.count > 0 {
                        listTableView.deleteRows(at: removed.map { IndexPath(item: $0, section:0) }, with: .automatic)
                    }
                    if let inserted = changes.insertedIndexes, inserted.count > 0{
                        listTableView.insertRows(at: inserted.map { IndexPath(item: $0, section:0) }, with: .automatic)
                    }
                    */
                    
                    /*
                    collectionView.performBatchUpdates({
                        // For indexes to make sense, updates must be in this order:
                        // delete, insert, reload, move
                        if let removed = changes.removedIndexes where removed.count > 0 {
                            collectionView.deleteItems(at: removed.map { IndexPath(item: $0, section:0) })
                        }
                        if let inserted = changes.insertedIndexes where inserted.count > 0 {
                            collectionView.insertItems(at: inserted.map { IndexPath(item: $0, section:0) })
                        }
                        if let changed = changes.changedIndexes where changed.count > 0 {
                            collectionView.reloadItems(at: changed.map { IndexPath(item: $0, section:0) })
                        }
                        changes.enumerateMoves { fromIndex, toIndex in
                            collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                    to: IndexPath(item: toIndex, section: 0))
                        }
                    })
                */
                } else {
                    // Reload the collection view if incremental diffs are not available.
                    print("no change")
                    listTableView.reloadData()
                }
            }
 */
        }
    }
    
    func reloadList(){
        
        recordings = CoreDataHelper.retrieveRecordings()
        listTableView.reloadData()
        /*
        var previews = [UIImage]()
        for recording in self.recordings{
            guard let url = recording.url else {
                return
            }
            previews.append(ImageCaptureHelper.videoPreviewUiimage(vidURL: URL(fileURLWithPath: url)) )
        }
        
        self.recordingPreviews = previews
        */
        /*
        PHPhotoLibrary.shared().register(self)
        
        PHPhotoLibrary.shared().performChanges({
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "localizedTitle = %@", "Method")
            let fetchCollectionResult  = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.any, options: fetchOptions)
            
            if fetchCollectionResult.count > 0{
                let assetCollection = fetchCollectionResult.object(at: 0)
                let options = PHFetchOptions()
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
                self.fetchResult = PHAsset.fetchAssets(in: assetCollection, options: options)
                let assets = self.fetchResult
                
                if (assets?.count)! > 0{
                    
                    let end = (assets?.count)! - 1
                    var array = [Int]()
                    for index in 0...end{
                        array.append(index)
                    }
                    let index = IndexSet(array)
                    
                    self.phAssets = (assets?.objects(at: index))!
                    
                    let size = CGSize(width: 50, height: 50)
                    let mode = PHImageContentMode.aspectFill
        
                    let imageOptions = PHImageRequestOptions()
                    imageOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
                    imageOptions.isNetworkAccessAllowed = true
                    imageOptions.isSynchronous = true
                    
                    let dgroup = DispatchGroup()
                    
                    for asset in self.phAssets{
                        dgroup.enter()
                        self.videoManager.requestImage(for: asset, targetSize: size, contentMode: mode, options: imageOptions, resultHandler: {(image: UIImage?, info: [AnyHashable: Any]?) -> Void in
                            print(image.debugDescription)
                            self.recordingPreviews.append(image!)
                            dgroup.leave()
                        })
                    }
                    
                    dgroup.notify(queue: .main){
                        print("reloading")
                        //self.recordingPreviews = previews
                        self.listTableView.reloadData()
                    }
                    //self.recordingPreviews = previews
                    
                }
            }
         
        })
    */
        /*
        UserService.retrieveRecords(for: User.current) { (recordings) in
            self.recordings = recordings
            
            print(recordings.count)
            
            let dispatchGroup = DispatchGroup()
            var previews = [UIImage]()
            
            for record in self.recordings{
                dispatchGroup.enter()
                DownloadService.download(record: record){ (videoURL) in
                    
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main){
                for record in self.recordings{
                    guard let url = record.localVideoURL else {
                        return
                    }
                    previews.append(ImageCaptureHelper.videoPreviewUiimage(vidURL: url, duration: record.duration) )
                }
                print("works")
                self.recordingPreviews = previews
            }
        }
         */
    }
    func tipsAction(sender: UIButton!) {
        print("tips pressed")
        AudioSessionCommandHelper.setAudioSessionCategoryPlayback()
        //let tip = Tips()
        //transcriptTextView.text = tip.tip
        
        let speaker = TextSpeaker()
        speaker.speak()
    }
    
    // MARK: RecordingViewController
    override func viewDidLoad() {
        super.viewDidLoad()
    
        videoManager = PHCachingImageManager()
        
        //listButton.isHidden = true
        //profileButton.isHidden = true
        /*
        displayView.frame = CGRect(x: 77, y: 536, width: 230, height: 48)
        self.view.addSubview(displayView)
        /* Start the tuner. */
        tuner.delegate = self
        tuner.startMonitoring()
        */
        
        configureTableView()
        reloadList()
        configureGestures()
        let frame = CGRect(x: 0, y: 80, width: 50, height: 50)
        let tips = UIButton(frame: frame)
        
        tips.backgroundColor = .clear
        tips.setTitle("Tips", for: .normal)
        tips.setTitleColor(UIColor.black, for: .normal)
        tips.addTarget(self, action: #selector(tipsAction), for: .touchUpInside)
        
        self.view.addSubview(tips)
        
        
        //Video Preview Layer
        previewLayer = PreviewView(frame: view.frame, videoGravity: videoGravity)
        previewLayer.session = videoSession
        self.view.insertSubview(previewLayer, at: 0)

        // Test authorization status for Camera and Micophone
        
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo){
        case .authorized:
            // already authorized
            break
        case .notDetermined:
            // not yet determined
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { [unowned self] granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
        default:
            // already been asked. Denied access
            setupResult = .notAuthorized
        }
        sessionQueue.async { [unowned self] in
            self.configureSession()
        }
        
        // Disable the record buttons until authorization has been granted.
        recordButton.isEnabled = false
        recordButton.setImage(UIImage(named: "RecordButton0"), for: .normal)
        
        listButton.setImage(UIImage(named: "List"), for: .normal)
        profileButton.setTitle("logout", for: .normal)
        //profileButton.setTitle(User.current.username, for: .normal)
        profileButton.setTitleColor(UIColor.white, for: .normal)
        //let profileImage = UIImage(named: "DefaultProfileButton")
        //profileButton.setImage(profileImage, for: .normal)
        //profileButton.layer.cornerRadius = 5
        //profileButton.layer.borderWidth = 1
        countingTimerLabel.text = "\(recordingTime)s"
        
    }

    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        layer.videoOrientation = orientation
        previewLayer.frame = self.view.bounds
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let connection =  self.previewLayer?.videoPreviewLayer.connection  {
            
            let currentDevice: UIDevice = UIDevice.current
            let orientation: UIDeviceOrientation = currentDevice.orientation
            let previewLayerConnection : AVCaptureConnection = connection
            if previewLayerConnection.isVideoOrientationSupported {
                switch (orientation) {
                case .portrait: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    break
                case .landscapeRight: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
                    break
                case .landscapeLeft: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
                    break
                case .portraitUpsideDown: updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
                    break
                default: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    break
                }
            }
        }
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Video
        if shouldUseDeviceOrientation {
            subscribeToDeviceOrientationChangeNotifications()
        }
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                // Begin Session
                self.videoSession.startRunning()
                self.isSessionRunning = self.videoSession.isRunning
                
                // Preview layer video orientation can be set only after the connection is created
                DispatchQueue.main.async {
                    self.previewLayer.videoPreviewLayer.connection?.videoOrientation = self.getPreviewLayerOrientation()
                }
            case .notAuthorized:
                // Prompt to App Settings
                self.promptToAppSettings()
            case .configurationFailed:
                // Unknown Error
                DispatchQueue.main.async(execute: { [unowned self] in
                    let message = NSLocalizedString("Unable to capture media", comment: "Alert message when something goes wrong during capture session configuration")
                    let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                })
            }
        }
        
        //Speech Recognition
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.recordButton.isEnabled = true
                case .denied:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("User denied access to speech recognition", for: .disabled)
                    
                case .restricted:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("Speech recognition restricted on this device", for: .disabled)
                    
                case .notDetermined:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("Speech recognition not yet authorized", for: .disabled)
                }
            }
        }
        
    }
    
    /// Handle Denied App Privacy Settings
    fileprivate func promptToAppSettings() {
        
        DispatchQueue.main.async(execute: { [unowned self] in
            let message = NSLocalizedString("AVCam doesn't have permission to use the camera, please change privacy settings", comment: "Alert message when the user has denied access to the camera")
            let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"), style: .default, handler: { action in
                if #available(iOS 10.0, *) {
                    //UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                    UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [UIApplicationOpenURLOptionUniversalLinksOnly: (Any).self] , completionHandler: nil)
                } else {
                    if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                        UIApplication.shared.openURL(appSettings)
                    }
                }
            }))
            self.present(alertController, animated: true, completion: nil)
        })
    }
    func configureGestures(){
        let scriptView = UIView.init(frame: scriptTextView.frame)
        scriptView.backgroundColor = .clear
        scriptTextView.addSubview(scriptView)
        scriptTextView.text = "Tap here for a movie quote"
        
        let scriptTapGesture = UITapGestureRecognizer(target: self, action: #selector(scriptGesture(write:)))
        scriptTapGesture.numberOfTapsRequired = 1
        scriptTapGesture.delegate = self
        scriptView.addGestureRecognizer(scriptTapGesture)
        
        let scriptLSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(scriptGesture(write:)))
        scriptLSwipeGesture.direction = .left
        scriptLSwipeGesture.delegate = self
        scriptView.addGestureRecognizer(scriptLSwipeGesture)
        
        let scriptRSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(scriptGesture(write:)))
        scriptRSwipeGesture.direction = .right
        scriptRSwipeGesture.delegate = self
        scriptView.addGestureRecognizer(scriptRSwipeGesture)
        
        /* //Future Gesture
        let leftTapFrame = CGRect(x: listTableView.frame.origin.x, y: listTableView.frame.origin.y, width: 50, height: listTableView.frame.height)
        let sideLeftTapView = UIView.init(frame: leftTapFrame)
        sideLeftTapView.backgroundColor = .clear
        listTableView.addSubview(sideLeftTapView)
        
        let tableViewLSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(listTableViewGesture(hide:)))
        scriptLSwipeGesture.direction = .left
        scriptLSwipeGesture.delegate = self
        sideLeftTapView.addGestureRecognizer(tableViewLSwipeGesture)
        */
    }
    
    fileprivate func configureSession(){
        guard setupResult == .success else {
            return
        }
        videoSession.beginConfiguration()
        
        configureVideoPreset()
        addVideoInput()
        addAudioInput()
        configureVideoOutput()
        videoSession.commitConfiguration()
    }
    
    fileprivate func configureVideoPreset(){
        if camera == .front {
            videoSession.sessionPreset = videoInputPresetFromVideoQuality(quality: .medium)
        } else {
            if videoSession.canSetSessionPreset(videoInputPresetFromVideoQuality(quality: videoQuality)) {
                videoSession.sessionPreset = videoInputPresetFromVideoQuality(quality: videoQuality)
            } else {
                videoSession.sessionPreset = videoInputPresetFromVideoQuality(quality: .medium)
            }
        }
    }
    fileprivate func addAudioInput() {
        guard audioEnabled == true else {
            return
        }
        do {
            let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            
            if videoSession.canAddInput(audioDeviceInput) {
                videoSession.addInput(audioDeviceInput)
            }
            else {
                print("Could not add audio device input to the session")
            }
        }
        catch {
            print("Could not create audio device input: \(error)")
        }
    }
    
    fileprivate func addVideoInput(){
        switch camera{
        case .front:
            videoDevice = RecordingViewController.deviceWithMediaType(AVMediaTypeVideo, preferringPosition: .front)
        case .rear:
            videoDevice = RecordingViewController.deviceWithMediaType(AVMediaTypeVideo, preferringPosition: .back)
        }
        
        if let device = videoDevice{
            do {
                try device.lockForConfiguration()
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                    if device.isSmoothAutoFocusSupported {
                        device.isSmoothAutoFocusEnabled = true
                    }
                }
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                    device.whiteBalanceMode = .continuousAutoWhiteBalance
                }
                if device.isLowLightBoostSupported && lowLightBoost == true {
                    device.automaticallyEnablesLowLightBoostWhenAvailable = true
                }
                
                device.unlockForConfiguration()
            } catch{
                print("Error locking configuration")
            }
        }

        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if videoSession.canAddInput(videoDeviceInput) {
                videoSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else{
                print(videoSession.canSetSessionPreset(videoInputPresetFromVideoQuality(quality: videoQuality)))
                setupResult = .configurationFailed
                videoSession.commitConfiguration()
                return
            }
        } catch{
            setupResult = .configurationFailed
            return
        }
    }
    
    fileprivate func configureVideoOutput() {
        let movieFileOutput = AVCaptureMovieFileOutput()
        
        if self.videoSession.canAddOutput(movieFileOutput) {
            self.videoSession.addOutput(movieFileOutput)
            if let connection = movieFileOutput.connection(withMediaType: AVMediaTypeVideo) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            self.movieFileOutput = movieFileOutput
        }
        
    }
    
    fileprivate func videoInputPresetFromVideoQuality(quality: VideoQuality) -> String{
        switch quality {
        case .high: return AVCaptureSessionPresetHigh
        case .medium: return AVCaptureSessionPresetMedium
        case .low: return AVCaptureSessionPresetLow
        case .resolution352x288: return AVCaptureSessionPreset352x288
        case .resolution640x480: return AVCaptureSessionPreset640x480
        case .resolution1280x720: return AVCaptureSessionPreset1280x720
        case .resolution1920x1080: return AVCaptureSessionPreset1920x1080
        case .iframe960x540: return AVCaptureSessionPresetiFrame960x540
        case .iframe1280x720: return AVCaptureSessionPresetiFrame1280x720
        case .resolution3840x2160:
            if #available(iOS 9.0, *) {
                return AVCaptureSessionPreset3840x2160
            } else{
                return AVCaptureSessionPresetHigh
            }
        }
    }
    
    // Get Device
    fileprivate class func deviceWithMediaType(_ mediaType: String, preferringPosition position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        
        if let deviceDescoverySession = AVCaptureDeviceDiscoverySession.init(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: AVCaptureDevicePosition.unspecified) {
            
            for device in deviceDescoverySession.devices {
                if device.position == position {
                    return device
                }
            }
        }
        return nil
    }
    
    fileprivate func subscribeToDeviceOrientationChangeNotifications() {
        self.deviceOrientation = UIDevice.current.orientation
        NotificationCenter.default.addObserver(self, selector: #selector(deviceDidRotate), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    @objc fileprivate func deviceDidRotate() {
        if !UIDevice.current.orientation.isFlat {
            self.deviceOrientation = UIDevice.current.orientation
        }
    }
    
    fileprivate func unsubscribeFromDeviceOrientationChangeNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        self.deviceOrientation = nil
    }
    
    fileprivate func getPreviewLayerOrientation() -> AVCaptureVideoOrientation {
        // Depends on layout orientation, not device orientation
        switch UIApplication.shared.statusBarOrientation {
        case .portrait, .unknown:
            return AVCaptureVideoOrientation.portrait
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeRight
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        }
    }
    
    fileprivate func getVideoOrientation() -> AVCaptureVideoOrientation {
        guard shouldUseDeviceOrientation, let deviceOrientation = self.deviceOrientation else { return previewLayer!.videoPreviewLayer.connection.videoOrientation }
        
        switch deviceOrientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    private func startAudioRecording() throws {
        
        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
            self.audioRecorder = nil
        }
        AudioSessionCommandHelper.setAudioSessionCategoryRecording()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true
        
        var average: Double = 0.0
        var sum: Float = 0.0
        var count: Float = 0.0
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                let range = NSMakeRange(self.transcriptTextView.text.characters.count - 1, 0)
                self.transcriptTextView.scrollRangeToVisible(range)
                
                let mainAttributedString : NSMutableAttributedString = NSMutableAttributedString(string: "", attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: 20.0)])
                for segment in result.bestTranscription.segments{
                    let confidence = segment.confidence
                    var string = segment.substring
                    string.append(" ")
                    var color: UIColor
                    if confidence > 0.86{
                        color = UIColor.green
                    } else if confidence > 0.7{
                        color = UIColor.yellow
                    } else if confidence > 0.4{
                        color = UIColor.orange
                    } else if confidence > 0.0{
                        color = UIColor.red
                    } else {
                        color = UIColor.white
                    }
                    
                    let attributedString = NSMutableAttributedString(string: string, attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: 20.0)])
                    
                    print("\(string): \(segment.confidence)")
                    
                    let range = (string as NSString).range(of: string)
                    attributedString.addAttribute(NSForegroundColorAttributeName, value: color , range: range)
                    
                    mainAttributedString.append(attributedString)
                }
                
                self.transcriptTextView.attributedText = mainAttributedString
                isFinal = result.isFinal
     
            }
            if error != nil || isFinal {
                
                print("Final")
                if let result = result{
                    for segment in result.bestTranscription.segments{
                        sum += segment.confidence
                        
                        let string = segment.substring
                        
                        print("\(string) confidence: \(segment.confidence)")
                        print("\(string) timestamp: \(segment.timestamp)")
                        print("\(string) duration: \(segment.duration)")
                        
                        count += 1
                    }
                }
                
                average = Double(sum / count)
                print("average: \(average)")
                self.articulationScore = average * 100.0
                print("articulation: \(self.articulationScore)")
                
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordButton.isEnabled = true
                
                self.presentAlert()
            
            }
        }
        
        //SFSpeechRecognitionTaskState.running
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }

        let audioOutputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((self.uniqueID as NSString).appendingPathExtension("m4a")!)
        
        let recordSettings:[String : Any] = [
            AVFormatIDKey:             kAudioFormatAppleLossless,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey :      32000,
            AVNumberOfChannelsKey:     2,
            AVSampleRateKey :          44100.0
        ]
        
        audioRecorder = try AVAudioRecorder(url: URL(fileURLWithPath: audioOutputFilePath), settings: recordSettings)
        audioRecorder.delegate = self
        
        audioEngine.prepare()
        
        audioRecorder.record()
        try audioEngine.start()
    }
    
    func startVideoRecording(){
        guard let movieFileOutput = self.movieFileOutput else{
            return
        }
        
        sessionQueue.async {[unowned self] in
            if !movieFileOutput.isRecording{
                if UIDevice.current.isMultitaskingSupported {
                    self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                }

                let movieFileOutputConnection = self.movieFileOutput?.connection(withMediaType: AVMediaTypeVideo)
                
                if self.camera == .front {
                    movieFileOutputConnection?.isVideoMirrored = true
                }
                
                movieFileOutputConnection?.videoOrientation = self.getVideoOrientation()
                
                // Start recording to a temporary file.
                let videoOutputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((self.uniqueID as NSString).appendingPathExtension("mov")!)
                movieFileOutput.startRecording(toOutputFileURL: URL(fileURLWithPath: videoOutputFilePath), recordingDelegate: self)
                
//                let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//                let localVideoURL = documentDirectoryURL.appendingPathComponent(self.uniqueID).appendingPathExtension("mov")
//               
//                movieFileOutput.startRecording(toOutputFileURL: localVideoURL, recordingDelegate: self)
            } else{
                movieFileOutput.stopRecording()
            }
        }
    }
    
    func stopVideoRecording(){
        if self.movieFileOutput?.isRecording == true{
            movieFileOutput!.stopRecording()

        }
    }
    func getTitle(sentence: String) -> String{
        
        let removedFirst = sentence.characters.dropFirst()
        let index = removedFirst.index(of: "\"")
        
        let index2 = removedFirst.index(index!, offsetBy: 2)
        
        let title = sentence.substring(from: index2)
        return title
    }
    
    func presentAlert(){
        
        //let movieTitle = self.getTitle(sentence: self.scriptTextView.text)
        
        let articulationScore = String(format: "%.01f", self.articulationScore)
        let alert = UIAlertController(title: "Recording Finished", message: "Your articulation score is\n \(articulationScore)% \n\n Transcript: \n\(self.transcriptTextView.text!)", preferredStyle: UIAlertControllerStyle.alert)
        
        
//        alert.addTextField { (textField : UITextField!) -> Void in
//            //textField.placeholder =  "\(movieTitle)" ?? "Enter recording title"
//            textField.placeholder =  "Enter recording title"
//        }
      
        alert.addAction(UIAlertAction(title: "Save", style: UIAlertActionStyle.default, handler: {[unowned self] action in

            /*
            let audioPath = (NSTemporaryDirectory() as NSString).appendingPathComponent((self.outputFileName as NSString).appendingPathExtension("m4a")!)
            guard let audioData = FileManager.default.contents(atPath: audioPath) else{
                return
            }
            */
            let videoPath = (NSTemporaryDirectory() as NSString).appendingPathComponent((self.uniqueID as NSString).appendingPathExtension("mov")!)
            
            /*
            guard let videoData = FileManager.default.contents(atPath: videoPath) else{
                return
            }
            */
            
            if FileManager.default.fileExists(atPath: videoPath){
                print("file added to temp ")
            } else{
                print("file not added to temp")
            }
            
            let videoUrl = URL(fileURLWithPath: videoPath)
            
            let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
            let videoDocPath = docPath.appendingPathComponent((self.uniqueID as NSString).appendingPathExtension("mov")!)

            let localVideoURL = URL(fileURLWithPath: videoDocPath)
            
            
            //let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            //let localVideoURL = documentDirectoryURL.appendingPathComponent(self.uniqueID).appendingPathExtension("mov")
           
            do {
                print("try add file locally")
                //try videoData.write(to: localVideoURL)
            
                try FileManager.default.copyItem(at: videoUrl, to: localVideoURL)
            
                print("local temp clear")
                FileManager.default.clearTmpDirectory()
            } catch{
                print("not copied/written")
                return
            }
            
            let transcriptText = self.transcriptTextView.text
           // let recordingNum = self.recordings.count + 1
            
            let recordingNum = self.phAssets.count + 1
            if self.isQuoteToggled == true{
                let movieTitle = self.getTitle(sentence: self.scriptTextView.text)
                self.currentFilename = "\(movieTitle)"
            } else{
                self.currentFilename = "Recording \(recordingNum) "
            }
            
            //self.currentFilename = "Recording \(recordingNum)"
            /*
            if alert.textFields?[0].text != "" {
                self.currentFilename = alert.textFields?[0].text
            }
             */
            
            let recording = CoreDataHelper.newRecording()
            recording.title = self.currentFilename
            recording.date = Date() as NSDate
            recording.transcript = transcriptText
            recording.score = self.articulationScore
            recording.url = videoDocPath
            CoreDataHelper.saveRecording()
            
            let albumName = "Method"
            RecordService.getAlbumWithName(name: albumName){ (album) in
                RecordService.addVideo(toUrl: localVideoURL, toAlbum: album!){(status) in
                    if status.self == true{
                        print("video added to library")
                    } else{
                        print("failed to add video to library")
                    }
                }
            }
            
            if self.recordings.count > 10{
                do{
                    print("oldest file removed")
                    //try FileManager.default.removeItem(at: URL(fileURLWithPath: self.recordings[first].url!))
                    //CoreDataHelper.delete(recording: self.recordings[first])
                    print(self.recordings[0].title!)
                    try FileManager.default.removeItem(at: URL(fileURLWithPath: self.recordings[0].url!))
                    CoreDataHelper.delete(recording: self.recordings[0])
                    
                } catch{
                    return
                }
            }
            
            self.reloadList()
           // RecordService.create(audioData: audioData, videoData: videoData, transcriptText: transcriptText!, title: self.currentFilename, fileID: self.outputFileName, duration: time, score: self.articulationScore ,preview: image)
    
        }))
        
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: { action in
            print("local temp clear")
            
            FileManager.default.clearTmpDirectory()
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    // MARK: SFSpeechRecognizerDelegate
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
        } else {
            recordButton.isEnabled = false
        }
    }
    
    //Counting Timer
    func runCountingTimer(){
        countingTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: (#selector(RecordingViewController.updateCountingTimer)), userInfo: nil, repeats: true)
    }
    
    func updateCountingTimer(){
        recordingTime = audioRecorder.currentTime
        let recordTime = String(format: "%.01f", recordingTime)
        countingTimerLabel.text = recordTime + "s"
    }
    
    //Countdown Timer
    func runCountdownTimer(){
        // 1.36363636364 for 60 seconds
        countdownTimer = Timer.scheduledTimer(timeInterval: 0.68181818181, target: self, selector: (#selector(RecordingViewController.updateCountdownTimer)), userInfo: nil, repeats: true)
    }
    
    func updateCountdownTimer(){
        if countdownTime > 0 {
            countdownTime -= 0.68181818181
            countdownImage += 1
            let button = UIImage(named: "RecordButton1 (\(countdownImage))")
            recordButton.setImage(button, for: .normal)
            
        } else{
            end()
            listButton.isEnabled = true
            isRecording = false
        }
    }

    func stopTimers(){
        countdownTimer.invalidate()
        countingTimer.invalidate()
    }
    
    func stopAudio(){
        audioEngine.stop()
        audioRecorder.stop()
        recognitionRequest?.endAudio()
    }
    
    func reset(){
        countdownTime = 30.0 - (2*0.68181818181)
        recordingTime = 0.0
        countingTimerLabel.text = "\(recordingTime)s"
        transcriptTextView.text = ""
        countdownImage = -1
        recordButton.setImage(UIImage(named: "RecordButton0"), for: .normal)
    }
    
    func end(){
        stopTimers()
        
        stopVideoRecording()
        stopAudio()
        
        //let time = self.recordingTime
        //self.presentAlert()
        recordButton.isEnabled = false
        reset()
    }
    
    @objc fileprivate func listTableViewGesture(hide: UISwipeGestureRecognizer) {
        listTableView.isHidden = true
    }
    
    @objc fileprivate func scriptGesture(write: UITapGestureRecognizer) {
        let text = getScript()
        scriptTextView.text = text
        let speaker = TextSpeaker()
        speaker.speakText(words: text)
        //scriptTextView.text = getScript()
    }
    
    func getScript() -> String{
        guard let jsonURL = Bundle.main.url(forResource: "movie-quotes", withExtension: "json") else {
            return "Could not find movie-quotes.json!"
        }
        let jsonData = try! Data(contentsOf: jsonURL)
        let json = JSON(jsonData)
        let script = Script(json: json)
        print(script.getTitle())
        isQuoteToggled = true
        return script.getQuote()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == Constants.Segue.showMedia {
                print("Table view cell tapped")
                
                let indexPath = listTableView.indexPathForSelectedRow!
                let recording = recordings[indexPath.row]
                let url = recording.url
                
                if url == nil{
                    print("Nil")
                } else{
                    print("URL: \(url!)")
                }
                
                let mediaPlayerViewController = segue.destination as! MediaPlayerViewController
                mediaPlayerViewController.url = URL(fileURLWithPath: url!)
                mediaPlayerViewController.transcriptText = recording.transcript
                
            }
        }
    }

    // MARK: Interface Builder actions
    
    @IBAction func recordButtonTapped(_ sender: UIButton) {
        
        listTableView.isHidden = true

        if audioEngine.isRunning{
            end()
            listButton.isEnabled = true
            isRecording = false
            /*
            for g in scriptTextView.gestureRecognizers!{
                g.isEnabled = true
            }
 */
        }
        else {
            uniqueID = UUID().uuidString
            try! startAudioRecording()
            startVideoRecording()
            
            /*
            for g in scriptTextView.gestureRecognizers!{
                g.isEnabled = false
            }
             */
            recordButton.setImage(UIImage(named: "RecordButtonPlayed"), for: .normal)
            listButton.isEnabled = false
            runCountdownTimer()
            runCountingTimer()
            isRecording = true
        }
    }
    
    @IBAction func listButtonTapped(_ sender: UIButton) {
        if listTableView.isHidden == true{
            listTableView.isHidden = false
        //    reloadList()
        }
        else{
            listTableView.isHidden = true
        }
    }
    
    @IBAction func profileButtonTapped(_ sender: UIButton) {
        
        
//        let alert = UIAlertController(title: "Logout?", message: "", preferredStyle: UIAlertControllerStyle.alert)
//        
//        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { action in
//            do{
//                let firebaseAuth = Auth.auth()
//                
//                try firebaseAuth.signOut()
//                print("signout")
//                self.dismiss(animated: true, completion: nil)
//                let initialViewController = UIStoryboard.initialViewController(for: .login)
//                let window = UIApplication.shared.keyWindow
//                window?.rootViewController = initialViewController
//            } catch let signOutError as NSError {
//                print ("Error signing out: %@", signOutError)
//            }
//            
//        }))
//        
//        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: { action in
//            
//        }))
//        
//        self.present(alert, animated: true, completion: nil)
                /*
        let transition = CATransition()
        transition.duration = 0.2
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromLeft
        view.window!.layer.add(transition, forKey: kCATransition)
        
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let profilePage = storyboard.instantiateViewController(withIdentifier: Constants.Storyboards.profileViewController) as? ProfileViewController
        self.present(profilePage!, animated: false, completion: nil)
 */
    }
    
    @IBAction func unwind(segue:UIStoryboardSegue) { }
    
}
extension RecordingViewController: UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return recordingPreviews.count
        return recordings.count
        
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "recordingTableViewCell", for: indexPath) as! RecordingTableViewCell
        let row = indexPath.row
        let recording = recordings[row]
        
        cell.recordingTitle.text = recording.title
        cell.recordingTitle.textColor = UIColor.white
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy h:mm a"
        let dateString = formatter.string(from: recording.date! as Date)
        cell.recordingDate.text = dateString
        cell.recordingDate.textColor = UIColor.white
        
        let score = recording.score
        cell.scoreLabel.text = String(format: "%.01f", recording.score).appending("%")
        
        var color: UIColor
        if score > 0.86{
            color = UIColor.green
        } else if score > 0.7{
            color = UIColor.yellow
        } else if score > 0.4{
            color = UIColor.orange
        } else if score > 0.0{
            color = UIColor.red
        } else {
            color = UIColor.white
        }
        
        cell.scoreLabel.textColor = color
        
        //cell.viewPreview.image = recordingPreviews[row]
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        return cell
    }
    
    /*
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //print("Delete")
           
            PHPhotoLibrary.shared().performChanges({
                
                let asset = self.phAssets[indexPath.row]
                
                let delAsset: NSMutableArray! = NSMutableArray()
                delAsset.add(asset)
                PHAssetChangeRequest.deleteAssets(delAsset)
                
                
                
            }){ deleted, error in
                if deleted {
                    print("deleted")
                    CoreDataHelper.delete(recording: self.recordings[indexPath.row])
                    self.recordings.remove(at: indexPath.row)
                    self.recordingPreviews.remove(at: indexPath.row)
                    self.listTableView.reloadData()
                }
            }
        }
    }
    */
}

extension RecordingViewController: AVCaptureFileOutputRecordingDelegate{
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        if let currentBackgroundRecordingID = backgroundRecordingID {
            backgroundRecordingID = UIBackgroundTaskInvalid
            
            if currentBackgroundRecordingID != UIBackgroundTaskInvalid {
                UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
            }
        }
    }
}

extension FileManager {
    func clearTmpDirectory() {
        //print("temp directoary being cleared")
        do {
            let tmpDirectory = try contentsOfDirectory(atPath: NSTemporaryDirectory())
            try tmpDirectory.forEach {[unowned self] file in
                let path = String.init(format: "%@%@", NSTemporaryDirectory(), file)
                try self.removeItem(atPath: path)
            }
        } catch {
            print(error)
        }
    }
    
    func removeFile(recording: Recording){
        do{
            try FileManager.default.removeItem(atPath: recording.url!)
        } catch{
            print(error)
        }
    }
    
    /*
    func removeFile(record: Recording){
        do{
            try FileManager.default.removeItem(atPath: (record.localAudioURL?.absoluteString)!)
            try FileManager.default.removeItem(atPath: (record.localVideoURL?.absoluteString)!)
        } catch{
            print(error)
        }
    }
   */
}


