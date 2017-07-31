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

class RecordingViewController: UIViewController, SFSpeechRecognizerDelegate, AVAudioRecorderDelegate{

    // MARK: Properties
    
    // Timer
    var countdownTime = 60.0
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
    private var recordingSession: AVAudioSession!
    private var audioRecorder: AVAudioRecorder!
    var soundFileURL:URL!
    var currentFilename: String!
    var currentRecording: Recording!
    
    //UI Elements

    @IBOutlet weak var transcriptTextView: UITextView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var countingTimerLabel: UILabel!
    
    // Video Setup
    
    fileprivate enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private var videoQuality: VideoQuality = .high
    private var videoGravity: VideoGravity = .resizeAspect
    private var camera: CameraSelection = .front
    private var videoSession = AVCaptureSession()

    var isVideoRecording = false
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
    
    // MARK: RecordingViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        //profileButton.backgroundColor = .clear
        profileButton.layer.cornerRadius = 5
        profileButton.layer.borderWidth = 1
        //profileButton.layer.borderColor = UIColor.black.cgColor
        
        self.countingTimerLabel.text = "\(recordingTime)s"
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
            videoSession.sessionPreset = videoInputPresetFromVideoQuality(quality: .high)
        } else {
            if videoSession.canSetSessionPreset(videoInputPresetFromVideoQuality(quality: videoQuality)) {
                videoSession.sessionPreset = videoInputPresetFromVideoQuality(quality: videoQuality)
            } else {
                videoSession.sessionPreset = videoInputPresetFromVideoQuality(quality: .high)
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
//        if let devices = AVCaptureDevice.devices(withMediaType: mediaType) as? [AVCaptureDevice] {
//            return devices.filter({ $0.position == position }).first
//        }
//        return nil
        
        if let deviceDescoverySession = AVCaptureDeviceDiscoverySession.init(deviceTypes: [AVCaptureDeviceType.builtInWideAngleCamera],
                                                                             mediaType: AVMediaTypeVideo,
                                                                             position: AVCaptureDevicePosition.unspecified) {
            
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
    
    func loadRecordingUI() {
        //recordButton = UIButton(frame: CGRect(x: 64, y: 64, width: 128, height: 64))
        //recordButton.setTitle("Tap to Record", for: .normal)
        //recordButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.title1)
        //recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        //view.addSubview(recordButton)
    }
    
    //Countdown Timer
    func runCountdownTimer(){
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.36363636364, target: self, selector: (#selector(RecordingViewController.updateCountdownTimer)), userInfo: nil, repeats: true)
    }
    
    func updateCountdownTimer(){
        if countdownTime > 0 {
            countdownTime -= 1.36363636364
            countdownImage += 1
            
            let button = UIImage(named: "RecordButton1 (\(countdownImage))")
            recordButton.setImage(button, for: .normal)
            
        } else{
            print("stopping")
            let time = recordingTime
            countdownTimer.invalidate()
            countingTimer.invalidate()
            
            audioEngine.stop()
            audioRecorder.stop()
            recognitionRequest?.endAudio()
            recordButton.isEnabled = false
            //recordButton.setTitle("Stopping", for: .disabled)
            
            stopVideoRecording()
            savingAlert(time: time)
            
            countdownTime = 60.0
            recordingTime = 0.0
            countingTimerLabel.text = "\(recordingTime)s"
            transcriptTextView.text = ""
            countdownImage = -1
            recordButton.setImage(UIImage(named: "RecordButton0"), for: .normal)
        }
    }
    
    //Counting Timer
    func runCountingTimer(){
        countingTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: (#selector(RecordingViewController.updateCountingTimer)), userInfo: nil, repeats: true)
    }
    
    func updateCountingTimer(){
        recordingTime = audioRecorder.currentTime
        countingTimerLabel.text = "\(recordingTime)s"
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
                //self.recordButton.setTitle("Start Recording", for: [])
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
        
        //transcriptTextView.text = "(Go ahead, I'm listening)"
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
               
                self.isVideoRecording = true
            } else{
                movieFileOutput.stopRecording()
            }
        }
    }
    
    func stopVideoRecording(){
        if self.movieFileOutput?.isRecording == true{
            self.isVideoRecording = false
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
            format.dateFormat = "yyyy-MM-dd-HH-mm-ss"
            self.currentFilename = "Recording-\(format.string(from: Date()))"
         
            RecordService.create(audioData: audioData, videoData: videoData, transcriptText: transcriptText!, title: self.currentFilename, time: time)
           
            self.removeFiles()
            
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.cancel, handler: { action in
            self.removeFiles()
        }))
        
        self.present(alert, animated: true, completion: nil)
        listButton.isEnabled = true
    }
    
    
    func removeFiles(){
        do{
            try FileManager.default.removeItem(atPath: self.audioOutputFilePath)
            try FileManager.default.removeItem(atPath: self.videoOutputFilePath)
        } catch{
            print(error)
        }
    }
    
    // MARK: SFSpeechRecognizerDelegate
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
            //recordButton.setTitle("Start Recording", for: [])
        } else {
            recordButton.isEnabled = false
            //recordButton.setTitle("Recognition not available", for: .disabled)
        }
    }
    
    
    // MARK: Interface Builder actions
    
    @IBAction func recordButtonTapped(_ sender: UIButton) {
        
        if audioEngine.isRunning {
            //print("\(recordingTime)")
            let time = recordingTime
            countdownTimer.invalidate()
            countingTimer.invalidate()
            audioEngine.stop()
            audioRecorder.stop()
            recognitionRequest?.endAudio()
            recordButton.isEnabled = false
            //recordButton.setTitle("Stopping", for: .disabled)
            
            stopVideoRecording()
            savingAlert(time: time)
            
            countdownTime = 60.0
            recordingTime = 0.0
            countingTimerLabel.text = "\(recordingTime)s"
            transcriptTextView.text = ""
            countdownImage = -1
            recordButton.setImage(UIImage(named: "RecordButton0"), for: .normal)
         
        } else {
            try! startAudioRecording()
            startVideoRecording()
            
            listButton.isEnabled = false
            runCountdownTimer()
            runCountingTimer()
        }
        
    }
    
    @IBAction func listButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let listPage = storyboard.instantiateViewController(withIdentifier: "recordsListViewController") as? RecordsListViewController
        self.present(listPage!, animated: true, completion: nil)
    }
    
    @IBAction func profileButtonTapped(_ sender: UIButton) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let profilePage = storyboard.instantiateViewController(withIdentifier: "profileViewController") as? ProfileViewController
        self.present(profilePage!, animated: true, completion: nil)
    }
}

extension RecordingViewController: AVCaptureFileOutputRecordingDelegate{
    
    /*!
     @method captureOutput:didFinishRecordingToOutputFileAtURL:fromConnections:error:
     @abstract
     Informs the delegate when all pending data has been written to an output file.
     
     @param captureOutput
     The capture file output that has finished writing the file.
     @param fileURL
     The file URL of the file that has been written.
     @param connections
     An array of AVCaptureConnection objects attached to the file output that provided the data that was written to the file.
     @param error
     An error describing what caused the file to stop recording, or nil if there was no error.
     
     @discussion
     This method is called when the file output has finished writing all data to a file whose recording was stopped, either because startRecordingToOutputFileURL:recordingDelegate: or stopRecording were called, or because an error, described by the error parameter, occurred (if no error occurred, the error parameter will be nil). This method will always be called for each recording request, even if no data is successfully written to the file.
     
     Clients should not assume that this method will be called on a specific thread.
     
     Delegates are required to implement this method.
     */
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        if let currentBackgroundRecordingID = backgroundRecordingID {
            backgroundRecordingID = UIBackgroundTaskInvalid
            
            if currentBackgroundRecordingID != UIBackgroundTaskInvalid {
                UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
            }
        }
    }
}

