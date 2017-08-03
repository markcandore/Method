//
//  RecordingViewController.swift
//  Method
//
//  Created by Mark Wang on 7/19/17.
//  Copyright © 2017 MarkWang. All rights reserved.
//

import UIKit
import Speech
import AVFoundation
import FirebaseStorage
import FirebaseDatabase
import SwiftyJSON

class RecordingViewController: UIViewController, SFSpeechRecognizerDelegate, AVAudioRecorderDelegate{

    // MARK: Properties
    
    // Face Detection
    //fileprivate var visage : Visage?
    //fileprivate let notificationCenter : NotificationCenter = NotificationCenter.default
    //let emojiLabel : UILabel = UILabel(frame: UIScreen.main.bounds)
    
    var isRecording = false
    // Timer
    var countdownTime = 30.0 - (2*0.68181818181)
    var countdownTimer = Timer()
    var isTimerRunning = false
    
    var countingTimer = Timer()
    var recordingTime = 0.0
    var finalTime = 0.0
    var countdownImage = -1
    
    //Speech Recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    //Audio
    private var audioRecorder: AVAudioRecorder!
    var soundFileURL:URL!
    var currentFilename: String!
    var currentRecording: Recording!
    
    //UI Elements
    @IBOutlet weak var listTableView: UITableView!
    @IBOutlet weak var transcriptTextView: UITextView!
    @IBOutlet weak var scriptTextView: UITextView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var countingTimerLabel: UILabel!
    @IBOutlet weak var scriptButton: UIButton!
    
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
    
    var videoOutputFilePath: String!
    var audioOutputFilePath: String!
    
    var recordings = [Recording]()
    var recordingPreviews = [UIImage](){
        didSet{
            print("reloading")
            self.listTableView.reloadData()
        }
    }
 
    
    func configureTableView() {
        listTableView.tableFooterView = UIView()
        listTableView.separatorStyle = .none
        listTableView.isHidden = true
    }
    
    func reloadList(){
       
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

    }
    
    func getScript() -> String{
        guard let jsonURL = Bundle.main.url(forResource: "movie-quotes", withExtension: "json") else {
            //print("Could not find movie-quotes.json!")
            return "Could not find movie-quotes.json!"
        }
        let jsonData = try! Data(contentsOf: jsonURL)
        let json = JSON(jsonData)
        let script = Script(json: json)
        return script.sentence
        
    }
    // MARK: RecordingViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        
        self.listTableView.dataSource = self
        configureTableView()
        reloadList()

        
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
        profileButton.setTitle(User.current.username, for: .normal)
        profileButton.setTitleColor(UIColor.white, for: .normal)
        //let profileImage = UIImage(named: "DefaultProfile")
        //profileButton.setImage(profileImage, for: .normal)
        profileButton.layer.cornerRadius = 5
        profileButton.layer.borderWidth = 1
        
        self.countingTimerLabel.text = "\(recordingTime)s"
        
        /*
        //Setup "Visage" with a camera-position (iSight-Camera (Back), FaceTime-Camera (Front)) and an optimization mode for either better feature-recognition performance (HighPerformance) or better battery-life (BatteryLife)
        visage = Visage(cameraPosition: Visage.CameraDevice.faceTimeCamera, optimizeFor: Visage.DetectorAccuracy.higherPerformance)
        
        //If you enable "onlyFireNotificationOnStatusChange" you won't get a continuous "stream" of notifications, but only one notification once the status changes.
        visage!.onlyFireNotificatonOnStatusChange = false
        
        
        //You need to call "beginFaceDetection" to start the detection, but also if you want to use the cameraView.
        visage!.beginFaceDetection()
        
        //This is a very simple cameraView you can use to preview the image that is seen by the camera.
        //let cameraView = visage!.visageCameraView
        //self.view.addSubview(cameraView)
        /*
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        visualEffectView.frame = self.view.bounds
        self.view.addSubview(visualEffectView)
        */
        emojiLabel.text = "😐"
        emojiLabel.font = UIFont.systemFont(ofSize: 50)
        emojiLabel.textAlignment = .center
        self.view.addSubview(emojiLabel)
        
        //Subscribing to the "visageFaceDetectedNotification" (for a list of all available notifications check out the "ReadMe" or switch to "Visage.swift") and reacting to it with a completionHandler. You can also use the other .addObserver-Methods to react to notifications.
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "visageFaceDetectedNotification"), object: nil, queue: OperationQueue.main, using: { notification in
            
            UIView.animate(withDuration: 0.5, animations: {
                self.emojiLabel.alpha = 1
            })
            
            if ((self.visage!.hasSmile == true && self.visage!.isWinking == true)) {
                self.emojiLabel.text = "😜"
            } else if ((self.visage!.isWinking == true && self.visage!.hasSmile == false)) {
                self.emojiLabel.text = "😉"
            } else if ((self.visage!.hasSmile == true && self.visage!.isWinking == false)) {
                self.emojiLabel.text = "😃"
            } else {
                self.emojiLabel.text = "😐"
            }
        })
        
        //The same thing for the opposite, when no face is detected things are reset.
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "visageNoFaceDetectedNotification"), object: nil, queue: OperationQueue.main, using: { notification in
            
            UIView.animate(withDuration: 0.5, animations: {
                self.emojiLabel.alpha = 0.25
            })
        })
 */
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
                //print("do app settings later")
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
            /*
             The callback may not be called on the main thread. Add an
             operation to the main queue to update the record button's state.
             */
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
    
    override func didReceiveMemoryWarning(){
        super.didReceiveMemoryWarning()
    }
    
    /// Handle Denied App Privacy Settings
    
    fileprivate func promptToAppSettings() {
        // prompt User with UIAlertView
        
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
    
    fileprivate func configureSession(){
        guard setupResult == .success else {
            return
        }
        videoSession.beginConfiguration()
        
        configureVideoPreset()
        addVideoInput()
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
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true
        
        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                let range = NSMakeRange(self.transcriptTextView.text.characters.count - 1, 0)
                self.transcriptTextView.scrollRangeToVisible(range)
                self.transcriptTextView.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordButton.isEnabled = true
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }

        let outputFileName = UUID().uuidString
        self.audioOutputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("m4a")!)
        
        let recordSettings:[String : Any] = [
            AVFormatIDKey:             kAudioFormatAppleLossless,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey :      32000,
            AVNumberOfChannelsKey:     2,
            AVSampleRateKey :          44100.0
        ]
        
        audioRecorder = try AVAudioRecorder(url: URL(fileURLWithPath: self.audioOutputFilePath!), settings: recordSettings)
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
                let outputFileName = UUID().uuidString
                self.videoOutputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
                movieFileOutput.startRecording(toOutputFileURL: URL(fileURLWithPath: self.videoOutputFilePath!), recordingDelegate: self)
               
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
    func savingAlert(time: TimeInterval){
        
        let alert = UIAlertController(title: "Recording Done", message: "Do you want to save this recording?", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Enter recording title"
        }
        
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { action in

            let audioPath = self.audioOutputFilePath
            guard let audioData = FileManager.default.contents(atPath: audioPath!) else{
                return
            }
            
            let videoPath = self.videoOutputFilePath
            guard let videoData = FileManager.default.contents(atPath: videoPath!) else{
                return
            }
            let transcriptText = self.transcriptTextView.text
            let format = DateFormatter()
            format.dateFormat = "MMM d, YYYY h:mm a"
            let recordingNum = self.recordings.count + 1
            self.currentFilename = "Recording \(recordingNum) - \(format.string(from: Date()))"
         
            if alert.textFields?[0].text != "" {
                self.currentFilename = alert.textFields?[0].text
            }
            let url = URL(fileURLWithPath: videoPath!)
            guard let image = ImageCaptureHelper.videoPreviewUiimage(vidURL: url, duration: time) else{
                return
            }
            
            if self.recordings.count > 10{
                RecordService.delete(record: self.recordings[0])
            }
            RecordService.create(audioData: audioData, videoData: videoData, transcriptText: transcriptText!, title: self.currentFilename, duration: time, preview: image)
          

            do{
                try FileManager.default.removeItem(at: URL(fileURLWithPath: self.audioOutputFilePath))
                try FileManager.default.removeItem(at: URL(fileURLWithPath: self.videoOutputFilePath))
            } catch{
                print(error)
            }
    
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.cancel, handler: { action in
            do{
                try FileManager.default.removeItem(at: URL(fileURLWithPath: self.audioOutputFilePath))
                try FileManager.default.removeItem(at: URL(fileURLWithPath: self.videoOutputFilePath))

            } catch{
                print(error)
            }
           
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
        let time = recordingTime
        stopTimers()
        stopAudio()
        stopVideoRecording()
        recordButton.isEnabled = false
        savingAlert(time: time)
        reset()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == Constants.Segue.showMedia {
                print("Table view cell tapped")
                
                let indexPath = listTableView.indexPathForSelectedRow!
                let record = recordings[indexPath.row]
                let mediaPlayerViewController = segue.destination
                    as! MediaPlayerViewController
                mediaPlayerViewController.record = record
            }
        }
    }

    // MARK: Interface Builder actions
    
    @IBAction func recordButtonTapped(_ sender: UIButton) {
        
        listTableView.isHidden = true
        
        if isRecording == false{
            try! startAudioRecording()
            startVideoRecording()
            
            recordButton.setImage(UIImage(named: "RecordButtonPlayed"), for: .normal)
            listButton.isEnabled = false
            runCountdownTimer()
            runCountingTimer()
            isRecording = true
        } else {
            end()
            listButton.isEnabled = true
            isRecording = false
        }
        /*
        if audioEngine.isRunning {
            end()
         
        } else {
            try! startAudioRecording()
            startVideoRecording()
            
            recordButton.setImage(UIImage(named: "RecordButtonPlayed"), for: .normal)
            listButton.isEnabled = false
            runCountdownTimer()
            runCountingTimer()
        }
 */
        
    }
    
    @IBAction func listButtonTapped(_ sender: UIButton) {
        if listTableView.isHidden == true{
            listTableView.isHidden = false
        }
        else{
            listTableView.isHidden = true
        }
    }
    
    @IBAction func profileButtonTapped(_ sender: UIButton) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let profilePage = storyboard.instantiateViewController(withIdentifier: Constants.Storyboards.profileViewController) as? ProfileViewController
        self.present(profilePage!, animated: true, completion: nil)
    }
    
    
    @IBAction func scriptButtonTapped(_ sender: UIButton) {
        print("script tapped")
        
        scriptTextView.text = getScript()
    }
    
    @IBAction func unwind(segue:UIStoryboardSegue) { }
    
}
extension RecordingViewController: UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordingPreviews.count
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("works")
        let cell = tableView.dequeueReusableCell(withIdentifier: "recordingTableViewCell", for: indexPath) as! RecordingTableViewCell
        let row = indexPath.row
        let recording = recordings[row]
        
        cell.recordingTitle.text = recording.title
        cell.recordingTitle.textColor = UIColor.white
        cell.recordingDate.text = recording.getDateString()
        cell.recordingDate.textColor = UIColor.white
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.viewPreview.image = recordingPreviews[row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            print("delete")
            RecordService.delete(record: recordings[indexPath.row])
        }
    }
    
}
/*
extension RecordingViewController:UIScrollViewDelegate{
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let index = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        print(index)
    }
}
 */
extension RecordingViewController: AVCaptureFileOutputRecordingDelegate{
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        if let currentBackgroundRecordingID = backgroundRecordingID {
            backgroundRecordingID = UIBackgroundTaskInvalid
            
            if currentBackgroundRecordingID != UIBackgroundTaskInvalid {
                UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
            }
        }
        
        guard let data = NSData(contentsOf: outputFileURL as URL) else {
            return
        }
        
        print("File size before compression: \(Double(data.length / 1048576)) mb")
        let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + NSUUID().uuidString + ".mov")
        compressVideo(inputURL: outputFileURL as URL, outputURL: compressedURL) { (exportSession) in
            guard let session = exportSession else {
                return
            }
            
            switch session.status {
            case .unknown:
                break
            case .waiting:
                break
            case .exporting:
                break
            case .completed:
                guard let compressedData = NSData(contentsOf: compressedURL) else {
                    return
                }
                print("File size after compression: \(Double(compressedData.length / 1048576)) mb")
            case .failed:
                break
            case .cancelled:
                break
            }
        }
    }
    
    func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) else {
            handler(nil)
            
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileTypeQuickTimeMovie
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
    }
}

extension FileManager {
    func clearTmpDirectory() {
        print("temp directoary being cleared")
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
    
    func removeFile(record: Recording){
        do{
            try FileManager.default.removeItem(atPath: (record.localAudioURL?.absoluteString)!)
            try FileManager.default.removeItem(atPath: (record.localVideoURL?.absoluteString)!)
        } catch{
            print(error)
        }
    }
}

