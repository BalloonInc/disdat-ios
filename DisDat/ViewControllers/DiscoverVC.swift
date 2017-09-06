//
//  ViewController.swift
//  VisionSample
//
//  Created by chris on 19/06/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import PopupDialog
import Firebase
import FirebaseStorage
import KDCircularProgress

class DiscoverVC: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var noCameraPermissions = false
    
    var screenHeight: CGFloat?
    
    var rootLanguage: String!
    var learningLanguage: String!
    
    var viewDidClear = true
    
    var lastClassificationRequestSent = Date()
    var lastClassificationPerformed = Date()
    
    var englishLabelDict: [String:Int] = [:]
    
    var rootLanguageLabels: [String] = []
    var learningLanguageLabels: [String] = []
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var camera: AVCaptureDevice?
    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    let captureQueue = DispatchQueue(label: "captureQueue")
    var gradientLayer: CAGradientLayer?
    var visionRequests = [VNRequest]()
    var modelName = "DisDat-v8"
    var paused = false
    
    var lastSuspicion: String = ""
    var lastSuspicionTime = Date()
    var lastGuess: String = ""
    
    var currentPixelBuffer: CVImageBuffer?
    
    var recognitionThreshold : Float = 0.90
    
    var debug = false
    var superDebug = false
    
    let minimumZoom: CGFloat = 1.0
    let maximumZoom: CGFloat = 3.0
    var lastZoomFactor: CGFloat = 1.0
    
    var progressCircle: KDCircularProgress?
    
    @IBOutlet weak var thresholdLabel: UILabel!
    @IBOutlet weak var thresholdSlider: UISlider!
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var resultView: UILabel!
    @IBOutlet weak var translatedResultView: UILabel!
    
    @IBOutlet weak var debugResultView: UITextView!
    @IBOutlet weak var debugFpsView: UILabel!
    @IBOutlet weak var debugImageView: UIImageView!
    @IBOutlet weak var crashButton: UIButton!
    @IBOutlet weak var speechBubbleContainer: UIView!
    @IBOutlet weak var speechBubbleShelf: UIView!
    @IBOutlet weak var zoomButton: UIButton!
    
    var speechBubble: UIView?
    
    @IBAction func enableDebug(_ sender: UITapGestureRecognizer) {
        debugFpsView.text = nil
        debugResultView.text = nil
        
        debug = !debug
        debugFpsView.isHidden = !debug
        debugResultView.isHidden = !debug
        debugImageView.isHidden = !debug
        crashButton.isHidden = !debug
    }
    
    @IBAction func enableSuperDebug(_ sender: UITapGestureRecognizer) {
        superDebug = !superDebug
        thresholdLabel.isHidden = !superDebug
        thresholdSlider.isHidden = !superDebug
    }
    
    @IBAction func crash(_ sender: Any) {
        Crashlytics.sharedInstance().crash()
    }
    
    @IBAction func sliderValueChanged(slider: UISlider) {
        self.recognitionThreshold = slider.value
        updateThresholdLabel()
    }
    @IBAction func zoomButtonPressed(_ sender: UIButton) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rootLanguage = Authentication.getInstance().currentRootLanguage!
        learningLanguage = Authentication.getInstance().currentLearningLanguage!
        
        englishLabelDict = DiscoveredWordCollection.getInstance()!.englishLabelDict
        
        rootLanguageLabels = DiscoveredWordCollection.getInstance()!.rootLanguageWords
        learningLanguageLabels = DiscoveredWordCollection.getInstance()!.learningLanguageWords
        
        loadCameraAndRequests()
        
        screenHeight = self.view.frame.height
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        resultView.text=nil
        translatedResultView.text=nil
        
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        switch cameraAuthorizationStatus {
        case .denied, .notDetermined, .restricted: do {
            showCameraPermissionsError()
            return
            }
        case .authorized: do {
            if noCameraPermissions {
                loadCameraAndRequests()
                noCameraPermissions = false
            }
            }
        }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.progressCircle = MainPVCContainer.instance?.discoverButton
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.session.isRunning{
                self.session.startRunning()
            }
        }
        self.viewDidClear=false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.progressCircle?.animate(toAngle: 0, duration: 0.3, completion: { success in
            self.progressCircle = nil})
        self.viewDidClear = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }
    
    fileprivate func showCameraPermissionsError() {
        noCameraPermissions = true
        DispatchQueue.main.async {
            let alert = PopupDialog(title:NSLocalizedString("Camera permissions", comment: ""), message:NSLocalizedString("Please go to the iOS preferences for this app and allow camera access in order to be able to use the app.", comment: ""))
            
            alert.addButton(DefaultButton(title: NSLocalizedString("Go to settings", comment: "")){
                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
            })
            alert.addButton(CancelButton(title:NSLocalizedString("Cancel", comment: "")){})
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    fileprivate func loadCameraAndRequests() {
       camera = AVCaptureDevice.default(for: .video)
        
        if camera == nil {
            showCameraPermissionsError()
            print("error - no camera 1")
            return
        }
        
        do {
            // add the preview layer
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
            
            previewView.layer.addSublayer(previewLayer!)
            // add a slight gradient overlay so we can read the results easily
            gradientLayer = CAGradientLayer()
            gradientLayer!.colors = [
                UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.7).cgColor,
                UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.0).cgColor,
            ]
            gradientLayer!.locations = [0.0, 0.3]
            self.previewView.layer.addSublayer(gradientLayer!)
            
            let cameraInput = try AVCaptureDeviceInput(device: camera!)
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: captureQueue)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            session.sessionPreset = .high
            
            session.addInput(cameraInput)
            session.addOutput(videoOutput)
            
            let conn = videoOutput.connection(with: .video)
            conn?.videoOrientation = .portrait
            
            guard let model = try? VNCoreMLModel(for: getModel(name:modelName)) else {
                fatalError("Could not load model")
            }
            let classificationRequest = VNCoreMLRequest(model: model, completionHandler: handleClassifications)
            classificationRequest.imageCropAndScaleOption = .centerCrop
            visionRequests = [classificationRequest]
            
        } catch {
            showCameraPermissionsError()
            print("error - no camera 2")
            return
        }
        
        updateThresholdLabel()
    }
    
    
    @IBAction func pinch(_ sender: UIPinchGestureRecognizer) {
        guard let device = camera else { return }
        
        // Return zoom value between the minimum and maximum zoom values
        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            return min(min(max(factor, minimumZoom), maximumZoom), device.activeFormat.videoMaxZoomFactor)
        }
        
        func update(scale factor: CGFloat) {
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                device.videoZoomFactor = factor
            } catch {
                print("\(error.localizedDescription)")
            }
        }
        
        let newScaleFactor = minMaxZoom(sender.scale * lastZoomFactor)
        
        if newScaleFactor < 1.01{
            zoomButton.isHidden = true
        }
        else {
            UIView.performWithoutAnimation {
                zoomButton.setTitle(String(format: "%.1fx", newScaleFactor), for: .normal)
                zoomButton.isHidden = false
                zoomButton.layoutIfNeeded()
            }
        }
        
        switch sender.state {
        case .began: fallthrough
        case .changed: update(scale: newScaleFactor)
        case .ended:
            lastZoomFactor = minMaxZoom(newScaleFactor)
            update(scale: lastZoomFactor)
        default: break
        }
    }

    
    func updateThresholdLabel () {
        self.thresholdLabel.text = "Threshold: " + String(format: "%.2f", recognitionThreshold)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.previewView != nil {
            previewLayer?.frame = self.previewView.bounds;
            gradientLayer?.frame = self.previewView.bounds;
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        if Date().timeIntervalSince(lastClassificationRequestSent)>1.0 {
            lastClassificationRequestSent = Date()
            connection.videoOrientation = .portrait
            
            var requestOptions:[VNImageOption: Any] = [:]
            
            if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
                requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
            }
            
            // for orientation see kCGImagePropertyOrientation
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored, options: requestOptions)
            do {
                self.currentPixelBuffer = pixelBuffer
                try imageRequestHandler.perform(self.visionRequests)
            } catch {
                print(error)
            }
        }
    }
    
    func handleClassifications(request: VNRequest, error: Error?) {
        if let theError = error {
            print("Error: \(theError.localizedDescription)")
            return
        }
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        let classificationsList = observations[0...4] // top 4 results
            .flatMap({ $0 as? VNClassificationObservation })
            .flatMap({$0.confidence > recognitionThreshold ? $0 : nil})
            .map({$0.identifier})
        

        let fullClassificationList = observations.flatMap({ $0 as? VNClassificationObservation }).map({"\($0.identifier) \(String(format: "%.2f %", $0.confidence*100))"})
        print("foreground: \(fullClassificationList[0...5])")
        
        DispatchQueue.main.async {
            let lastClassificationTime = Date().timeIntervalSince(self.lastClassificationPerformed)*1000
            
            if self.debug {
                self.debugResultView.text = fullClassificationList[0...5].joined(separator:"\n")
                self.debugFpsView.text = String(format: "%.2f ms", lastClassificationTime)
                if let currentBuffer = self.currentPixelBuffer{
                    self.debugImageView.image = self.convert(cmage: CIImage(cvPixelBuffer: currentBuffer), crop: true)
                }
            }
            
            let confidence = (observations[0] as! VNClassificationObservation).confidence
            let suspicion = (observations[0] as! VNClassificationObservation).identifier
            let duration = confidence > self.recognitionThreshold ? 0.25 : min(lastClassificationTime/1000,1)
            
            if confidence > 0.8 * self.recognitionThreshold && confidence < self.recognitionThreshold {
                if self.lastSuspicion != suspicion {
                    self.lastSuspicionTime = Date()
                    self.lastSuspicion = suspicion
                    self.speechBubble?.removeFromSuperview()
                    let category = DiscoveredWordCollection.getInstance()!.getLearningCategory(word: self.learningLanguageLabels[self.englishLabelDict[suspicion]!])
                    
                    let bubbleText = String(format: NSLocalizedString("I think I see something in the category %@. Try a different angle.", comment: ""), category)
                    
                    let attributedBubbleText = NSMutableAttributedString.init(string: bubbleText)
                    
                    let paragraph = NSMutableParagraphStyle()
                    paragraph.alignment = .center
                    
                    attributedBubbleText.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.1732688546, green: 0.7682885528, blue: 0.6751055121, alpha: 1) , range: (bubbleText as NSString).range(of: category))
                    attributedBubbleText.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: bubbleText.count))
                    
                    self.speechBubble = SpeechBubble(baseView: self.speechBubbleShelf, containingView: self.speechBubbleContainer, attributedText: attributedBubbleText)
                    self.speechBubbleContainer.addSubview(self.speechBubble!)
                }
            }
            else if Date().timeIntervalSince(self.lastSuspicionTime) > 3 || confidence > self.recognitionThreshold {
                self.speechBubble?.removeFromSuperview()
            }
            var progressAngle = min(Double(360.0*confidence/self.recognitionThreshold),360)
            // this is to avoid
            if progressAngle > 345 && progressAngle < 360.0{
                progressAngle = 345
            }
            
            self.progressCircle?.animate(toAngle: progressAngle, duration: duration , completion: { success in
                if self.viewDidClear {
                    self.progressCircle?.animate(toAngle: 0, duration: 0.5, completion:nil)
                }
            }
            )
            
            self.lastClassificationPerformed = Date()
        }
        
        let rootLanguageClassifications = classificationsList.map( {englishLabelDict[$0] != nil ?rootLanguageLabels[englishLabelDict[$0]!]:$0}).joined(separator:"\n")
        let learnedLanguageClassifications = classificationsList.map( {englishLabelDict[$0] != nil ?learningLanguageLabels[englishLabelDict[$0]!]:""}).joined(separator:"\n")
        
        if classificationsList.isEmpty {
            DispatchQueue.main.async {
                self.resultView.text = ""
                self.translatedResultView.text = ""
            }
            return
        }
        
        DispatchQueue.main.async {
            self.resultView.text = rootLanguageClassifications
            self.translatedResultView.text = learnedLanguageClassifications
        }
        
        if !DiscoveredWordCollection.getInstance()!.isDiscovered(englishWord: classificationsList[0]){
            session.stopRunning()
            
            let foundTranslatedWord = String(learnedLanguageClassifications.split(separator: "\n")[0])
            let foundOriginalWord = String(rootLanguageClassifications.split(separator: "\n")[0])
            let foundEnglishWord = classificationsList[0]
            
            if let currentBuffer = self.currentPixelBuffer{
                let ciImage = CIImage(cvPixelBuffer: currentBuffer)
                self.currentPixelBuffer = nil
                let image = self.convert(cmage: ciImage, crop: true)
                
                displayFoundWordPopup(learnedLanguageClassifications, foundTranslatedWord, foundOriginalWord, foundEnglishWord, image, fullClassificationList)
            }
            return
        }
        else {
            self.currentPixelBuffer = nil
        }
    }
    
    fileprivate func saveImageToFirebase(englishWord: String, fullPredictions: [String], image: UIImage, correct: Bool) {
        guard let currentUser = Auth.auth().currentUser else {return}
        
        let storageRef = Storage.storage().reference()
        
        var rootFolder = storageRef.child(correct ? "correct_images" : "false_positives").child(currentUser.uid)

        if correct {
            rootFolder = rootFolder.child("\(rootLanguage!)-\(learningLanguage!)")
        }
        
        let imageRef = rootFolder.child(englishWord+".png")
        let txtRef = rootFolder.child(englishWord+".json")
        
        let data = UIImageJPEGRepresentation(image.resize(toWidth: 300)!, 0.8)!
        
        let metaData: [String:Any] = ["predictions":Array(fullPredictions[0...10]),
                                      "device":UIDevice.current.modelName,
                                      "orientation":Helpers.getOrientationString(),
                                      "OS version":UIDevice.current.systemVersion,
                                      "Battery level":UIDevice.current.batteryLevel,
                                      "App version":Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String,
                                      "App build number": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        ]
        
        let fileURL = self.getTempURL(fileName: "metadata_temp.json")
        
        imageRef.putData(data, metadata:nil) { (metadata, error) in
            guard let metadata = metadata else {
                print("Could not upload image: \(error?.localizedDescription ?? "")")
                return
            }
            print("uploaded image to path: \(metadata.downloadURL()?.absoluteString ?? "")")
            
            do {
                let data = try JSONSerialization.data(withJSONObject: metaData, options: [])
                try data.write(to: fileURL!, options: [])
                txtRef.putFile(from: fileURL!, metadata: nil, completion: { (metadata, error) in
                    if let error = error {
                        print("Could not upload text json: \(error.localizedDescription)")
                        return
                    }
                    else {
                        print("File succesfully uploaded at path: \(metadata?.downloadURL()?.absoluteString ?? "")")
                    }
                    try? FileManager.default.removeItem(atPath: fileURL!.path)
                })
            } catch {
                print(error)
            }
        }
    }
    
    fileprivate func displayFoundWordPopup(_ learnedLanguageClassifications: String, _ foundTranslatedWord: String, _ foundOriginalWord: String, _ foundEnglishWord: String,  _ image: UIImage, _ fullPredictions: [String]) {
        
        let rootCategory = DiscoveredWordCollection.getInstance()!.getRootCategory(word: foundOriginalWord)
        let translatedCategory = DiscoveredWordCollection.getInstance()!.getLearningCategory(word: foundTranslatedWord)
        
        let title = String(format: NSLocalizedString("You found a new word in the category %@ - %@:",comment:""),translatedCategory, rootCategory)
        let message = "\(foundTranslatedWord)\n\(foundOriginalWord)"
        let translatedWordRange = (message as NSString).range(of: foundTranslatedWord)
        let originalWordRange = (message as NSString).range(of: foundOriginalWord)
        let attributedTitle = NSMutableAttributedString.init(string: title)
        let attributedMessage = NSMutableAttributedString.init(string: message)
        
        attributedTitle.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.1732688546, green: 0.7682885528, blue: 0.6751055121, alpha: 1) , range: (title as NSString).range(of: translatedCategory))
        attributedTitle.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1) , range: (title as NSString).range(of: rootCategory))
        
        attributedMessage.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.1732688546, green: 0.7682885528, blue: 0.6751055121, alpha: 1) , range: translatedWordRange)
        attributedMessage.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1) , range: originalWordRange)
        attributedMessage.addAttribute(.font, value: UIFont.systemFont(ofSize: 38, weight: .regular), range: translatedWordRange)
        attributedMessage.addAttribute(.font, value: UIFont.systemFont(ofSize: 18, weight: .regular), range: originalWordRange)
        
        let alert = PopupDialog(title:nil, message: nil, attributedTitle:attributedTitle, attributedMessage:attributedMessage, image: image, gestureDismissal: false)
        
        alert.addButton(DefaultButton(title: NSLocalizedString("Great!",comment:"")){
            DiscoveredWordCollection.getInstance()!.discovered(englishWord: foundEnglishWord)
            self.saveImageToFirebase(englishWord: foundEnglishWord, fullPredictions: fullPredictions, image: image, correct: true)
                self.session.startRunning()
        })
        
        alert.addButton(DefaultButton(title: NSLocalizedString("This is wrong.", comment: "Wrong detection")){
            if Auth.auth().currentUser != nil {
                let uploadAlert = PopupDialog(title:NSLocalizedString("I was wrong... 🤓",comment:""), message:NSLocalizedString("Do you want to report this to my creators? This means a human might look at your image and investigate.", comment:""), image: image, gestureDismissal: false)
                uploadAlert.addButton(DefaultButton(title: NSLocalizedString("Yes", comment:"")){
                    
                    self.saveImageToFirebase(englishWord: foundEnglishWord, fullPredictions: fullPredictions, image: image, correct: false)
                    self.session.startRunning()
                })
                uploadAlert.addButton(DefaultButton(title: NSLocalizedString("No", comment:"")){
                    self.session.startRunning()
                })
                self.present(uploadAlert, animated: true, completion: nil)
            }
        })
        
        alert.addButton(DefaultButton(image: UIImage(named: "speaker"), dismissOnTap: false){
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                try AVAudioSession.sharedInstance().setActive(true)
                
                let pronounceString = "\(learnedLanguageClassifications.split(separator: "\n")[0])"
                let speechUtterance = AVSpeechUtterance(string: pronounceString)
                speechUtterance.voice  = AVSpeechSynthesisVoice(language: DiscoveredWordCollection.getInstance()!.learningLanguage)
                self.speechSynthesizer.speak(speechUtterance)
            }
            catch let error as NSError {
                print("Error: error activating speech: \(error), \(error.userInfo)")
            }
        })
        
        DispatchQueue.main.async {
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func getTempURL(fileName: String) -> URL? {
        do {
            let dirURL = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            return dirURL.appendingPathComponent(fileName)
        }
        catch {
            return nil
        }
    }
    
    func getModel(name: String) -> MLModel{
        switch modelName {
        case "DisDat-v8":
            return disdatkerasv8().model
        default:
            return disdatkerasv8().model
        }
    }
    
    func convert(cmage:CIImage, crop: Bool) -> UIImage
    {
        let context = CIContext.init(options: nil)
        var  cgImage = context.createCGImage(cmage, from: cmage.extent)!
        if crop {
            cgImage = cgImage.cropToSquare()!
        }
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
}
