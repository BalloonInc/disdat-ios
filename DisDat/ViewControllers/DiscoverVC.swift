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
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var camera: AVCaptureDevice?
    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    let captureQueue = DispatchQueue(label: "captureQueue")
    var gradientLayer: CAGradientLayer?
    var visionRequests = [VNRequest]()
    var modelName = "DisDat-v8"
    var paused = false
    var introShowing = false
    
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
    @IBOutlet weak var speechBubbleContainer: UIView!
    @IBOutlet weak var speechBubbleShelf: UIView!
    @IBOutlet weak var zoomButton: UIButton!
    @IBOutlet weak var disLabel: UILabel!
    @IBOutlet weak var datLabel: UILabel!
    @IBOutlet weak var optionsButton: UIButton!
    
    @IBOutlet weak var zoomCirleView: UIView!
    var speechBubble: UIView?
    
    @IBAction func enableDebug(_ sender: UITapGestureRecognizer) {
        if !FirebaseConnection.getBoolParam(Constants.config.debug_enabled){
            return
        }
        debugFpsView.text = nil
        debugResultView.text = nil
        
        debug = !debug
        debugFpsView.isHidden = !debug
        debugResultView.isHidden = !debug
        debugImageView.isHidden = !debug
    }
    
    @IBAction func enableSuperDebug(_ sender: UITapGestureRecognizer) {
        if !FirebaseConnection.getBoolParam(Constants.config.super_debug_enabled){
            return
        }
        
        superDebug = !superDebug
        thresholdLabel.isHidden = !superDebug
        thresholdSlider.isHidden = !superDebug
    }
    
    @IBAction func sliderValueChanged(slider: UISlider) {
        self.recognitionThreshold = slider.value
        updateThresholdLabel()
    }
    
    @IBAction func zoomButtonPressed(_ sender: UIButton) {
        pinch(scale: 0, state: .ended)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rootLanguage = Authentication.getInstance().currentRootLanguage!
        learningLanguage = Authentication.getInstance().currentLearningLanguage!
        
        englishLabelDict = DiscoveredWordCollection.getInstance()!.englishLabelDict
        
        loadCameraAndRequests()
        
        screenHeight = self.view.frame.height
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FirebaseConnection.fetchConfig()
        
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
            if !UserDefaults.standard.bool(forKey:"didShowIntro") {
                showIntroBubble()
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
        UIView.animate(withDuration: 0.5) {
            self.disLabel.alpha = 1
            self.datLabel.alpha = 1
            self.optionsButton.alpha = 1
        }
        self.viewDidClear=false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIView.animate(withDuration: 0.2) {
            self.disLabel.alpha = 0
            self.datLabel.alpha = 0
            self.optionsButton.alpha = 0
        }
        
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
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        layer.videoOrientation = orientation
        previewLayer?.frame = self.view.bounds
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        configureZoomButton()
        if self.previewView != nil {
            previewLayer?.frame = self.previewView.bounds;
            gradientLayer?.frame = self.previewView.bounds;
        }
        
        if let connection =  self.previewLayer?.connection  {
            let orientation: UIDeviceOrientation = UIDevice.current.orientation
            
            if connection.isVideoOrientationSupported {
                switch (orientation) {
                case .portrait:
                    updatePreviewLayer(layer: connection, orientation: .portrait)
                case .landscapeRight:
                    updatePreviewLayer(layer: connection, orientation: .landscapeLeft)
                case .landscapeLeft:
                    updatePreviewLayer(layer: connection, orientation: .landscapeRight)
                case .portraitUpsideDown:
                    updatePreviewLayer(layer: connection, orientation: .portraitUpsideDown)
                default: updatePreviewLayer(layer: connection, orientation: .portrait)
                }
            }
        }
    }
    
    func configureZoomButton()
    {
        zoomCirleView.layer.cornerRadius = 0.5 * zoomCirleView.bounds.size.width
        zoomCirleView.layer.borderColor = UIColor.white.cgColor
        zoomCirleView.layer.borderWidth = 1.0
        zoomCirleView.clipsToBounds = true
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
            
            guard let model = try? VNCoreMLModel(for: disdatkerasv8().model) else {
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
        pinch(scale: sender.scale, state: sender.state )
    }
    
    func pinch(scale: CGFloat, state: UIGestureRecognizerState){
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
        
        var newScaleFactor = minMaxZoom(scale * lastZoomFactor)
        
        if newScaleFactor < 1.01{
            newScaleFactor = 1.0
            zoomButton.isHidden = true
            zoomCirleView.isHidden = true
        }
        else {
            UIView.performWithoutAnimation {
                zoomButton.setAttributedTitle(NSAttributedString(string: String(format: " %.1fx ", newScaleFactor)), for: .normal)
                zoomButton.isHidden = false
                zoomCirleView.isHidden = false
                zoomButton.layoutIfNeeded()
            }
        }
        
        switch state {
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
    
    func showIntroBubble(){
        introShowing = true
        
        let bubbleText = NSLocalizedString("This circle indicates my confidence. When it is full, I am can tell you what you are pointing at.", comment: "")
        
        let attributedBubbleText = NSMutableAttributedString.init(string: bubbleText)
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        attributedBubbleText.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: bubbleText.count))
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.speechBubble?.removeFromSuperview()
            self.speechBubble = SpeechBubble(baseView: self.speechBubbleShelf, containingView: self.speechBubbleContainer, attributedText: attributedBubbleText)
            self.speechBubbleContainer.addSubview(self.speechBubble!)
            
            self.progressCircle?.animate(toAngle: 320, duration: 2.0, completion: { _ in
                self.progressCircle?.animate(toAngle: 0, duration: 2.0, completion: nil)
            })
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
                self.speechBubble?.removeFromSuperview()
                self.introShowing = false
                UserDefaults.standard.set(true, forKey: "didShowIntro")
            }
        }
    }
    
    func removeBubble(){
        
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
    
    func isExcluded(_ observation: VNClassificationObservation) -> Bool
    {
        return DiscoveredWordCollection.getInstance()!.englishWordsToExclude.contains(observation.identifier)
    }
    
    func getConfidence(for observation: VNClassificationObservation) -> Float{
        if observation.identifier == "keyboard"{
            return min(1.0, observation.confidence/0.97)
        }
        return min(1.0, observation.confidence/self.recognitionThreshold)
    }
    
    func isConfidentEnough(for observation: VNClassificationObservation) -> Bool {
        return getConfidence(for: observation) > 1 - 1E-5
    }
    
    func handleClassifications(request: VNRequest, error: Error?) {
        if let theError = error {
            print("Error: \(theError.localizedDescription)")
            return
        }
        guard var observations = request.results else {
            print("No results")
            return
        }
        if introShowing { return }
        
        observations = observations.filter({ !isExcluded($0 as! VNClassificationObservation)})
        
        let classificationsList = observations[0...4] // top 4 results
            .flatMap({ $0 as? VNClassificationObservation })
            .filter({isConfidentEnough(for: $0)})
            .map({$0.identifier})
        
        let fullClassificationList = observations.flatMap({ $0 as? VNClassificationObservation }).map({"\($0.identifier) \(String(format: "%.2f %", $0.confidence*100))"})
        print("foreground: \(fullClassificationList[0...5])")
        
        guard let index = englishLabelDict[(observations[0] as! VNClassificationObservation).identifier] else {
            DispatchQueue.main.async {
                self.resultView.text = ""
                self.translatedResultView.text = ""
            }
            return
        }
        
        DispatchQueue.main.async {
            let lastClassificationTime = Date().timeIntervalSince(self.lastClassificationPerformed)*1000
            
            if self.debug {
                self.debugResultView.text = fullClassificationList[0...5].joined(separator:"\n")
                self.debugFpsView.text = String(format: "%.2f ms", lastClassificationTime)
                if let currentBuffer = self.currentPixelBuffer{
                    self.debugImageView.image = self.convert(cmage: CIImage(cvPixelBuffer: currentBuffer), crop: true)
                }
            }
            
            let confidence = self.getConfidence(for:(observations[0] as! VNClassificationObservation))
            let suspicion = (observations[0] as! VNClassificationObservation).identifier
            let duration = self.isConfidentEnough(for: observations[0] as! VNClassificationObservation) ? 0.25 : min(lastClassificationTime/1000,1)
            
            if confidence > 0.8 && confidence < 1.0 - 1E-5 {
                if self.lastSuspicion != suspicion {
                    self.lastSuspicionTime = Date()
                    self.lastSuspicion = suspicion
                    self.speechBubble?.removeFromSuperview()
                    
                    let learningLanguageWord = DiscoveredWordCollection.getInstance()!.getLearningWord(at: index, withArticle: false)
                    let category = DiscoveredWordCollection.getInstance()!.getLearningCategory(word: learningLanguageWord)
                    
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
            else if Date().timeIntervalSince(self.lastSuspicionTime) > 3 || confidence > 0.8 {
                self.speechBubble?.removeFromSuperview()
            }
            var progressAngle = min(Double(360.0*confidence),360)
            // this is to avoid an almost full circle without recognition
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
        
        if classificationsList.isEmpty {
            DispatchQueue.main.async {
                self.resultView.text = ""
                self.translatedResultView.text = ""
            }
            return
        }
        
        let foundEnglishWord = classificationsList[0]
        
        let rootLanguageClassification = DiscoveredWordCollection.getInstance()!.getRootWord(at: index, withArticle: true)
        let learnedLanguageClassification = DiscoveredWordCollection.getInstance()!.getLearningWord(at: index, withArticle: true)
        
        DispatchQueue.main.async {
            self.resultView.text = rootLanguageClassification
            self.translatedResultView.text = learnedLanguageClassification
        }
        
        if !DiscoveredWordCollection.getInstance()!.isDiscovered(englishWord: foundEnglishWord){
            session.stopRunning()
            
            if let currentBuffer = self.currentPixelBuffer{
                let ciImage = CIImage(cvPixelBuffer: currentBuffer)
                self.currentPixelBuffer = nil
                let image = self.convert(cmage: ciImage, crop: true)
                
                displayFoundWordPopup(index, image, fullClassificationList)
            }
            return
        }
        else {
            FirebaseConnection.logEvent(title: "recog_again", content: foundEnglishWord)
            self.currentPixelBuffer = nil
        }
    }
    
    fileprivate func displayFoundWordPopup(_ index: Int,  _ image: UIImage, _ fullPredictions: [String]) {
        
        let foundEnglishWord = DiscoveredWordCollection.getInstance()!.getEnglishWord(at: index)
        let rootLanguageWord = DiscoveredWordCollection.getInstance()!.getRootWord(at: index, withArticle: false)
        let learningLanguageWord = DiscoveredWordCollection.getInstance()!.getLearningWord(at: index, withArticle: false)
        
        let rootLanguageWordWithArticle = DiscoveredWordCollection.getInstance()!.getRootWord(at: index, withArticle: true)
        let learningLanguageWordWithArticle = DiscoveredWordCollection.getInstance()!.getLearningWord(at: index, withArticle: true)
        
        let rootCategory = DiscoveredWordCollection.getInstance()!.getRootCategory(word: rootLanguageWord)
        let translatedCategory = DiscoveredWordCollection.getInstance()!.getLearningCategory(word: learningLanguageWord)
        
        let attributedTitle = getAttributedTitle(rootCategory: rootCategory, translatedCategory: translatedCategory)
        
        let attributedMessage = getAttributedMessage(foundTranslatedWord: learningLanguageWordWithArticle, foundOriginalWord: rootLanguageWordWithArticle)
        
        let alert = PopupDialog(title:nil, message: nil, attributedTitle:attributedTitle, attributedMessage:attributedMessage, textMargin: 10, image: image, gestureDismissal: false)
        
        alert.addButton(DefaultButton(title: NSLocalizedString("Great!",comment:"")){
            DiscoveredWordCollection.getInstance()!.discovered(englishWord: foundEnglishWord)
            FirebaseConnection.saveImageToFirebase(englishWord: foundEnglishWord, fullPredictions: fullPredictions, image: image, correct: true)
            FirebaseConnection.logEvent(title: "recog_correct", content: foundEnglishWord)
            self.session.startRunning()
        })
        
        alert.addButton(DefaultButton(title: NSLocalizedString("This is wrong.", comment: "Wrong detection")){
            if Auth.auth().currentUser != nil {
                FirebaseConnection.logEvent(title: "recog_wrong", content: foundEnglishWord)
                
                let uploadAlert = PopupDialog(title:NSLocalizedString("I was wrong... 🤓",comment:""), message:NSLocalizedString("Do you want to report this to my creators? This means a human might look at your image and investigate.", comment:""), image: image, gestureDismissal: false)
                uploadAlert.addButton(DefaultButton(title: NSLocalizedString("Yes", comment:"")){
                    
                    FirebaseConnection.saveImageToFirebase(englishWord: foundEnglishWord, fullPredictions: fullPredictions, image: image, correct: false)
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
                
                let speechUtterance = AVSpeechUtterance(string: learningLanguageWordWithArticle)
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
    
    func getAttributedTitle(rootCategory: String, translatedCategory: String) -> NSMutableAttributedString{
        let title = String(format: NSLocalizedString("You found a new word in the category %@ - %@:",comment:""), "{1}", "{2}")
        let attributedTitle = NSMutableAttributedString.init(string: title)
        
        let translatedAttString = NSMutableAttributedString(string: translatedCategory)
        let originalAttString = NSMutableAttributedString(string: rootCategory)
        
        translatedAttString.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.1732688546, green: 0.7682885528, blue: 0.6751055121, alpha: 1) , range: (translatedCategory as NSString).range(of: translatedCategory))
        originalAttString.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1) , range: (rootCategory as NSString).range(of: rootCategory))
        
        attributedTitle.replaceCharacters(in: (title as NSString).range(of: "{2}"), with: originalAttString)
        attributedTitle.replaceCharacters(in: (title as NSString).range(of: "{1}"), with: translatedAttString)
        
        return attributedTitle
    }
    
    func getAttributedMessage(foundTranslatedWord: String, foundOriginalWord: String) -> NSAttributedString{
        
        let translatedAttString = NSMutableAttributedString(string: foundTranslatedWord)
        let originalAttString = NSMutableAttributedString(string: foundOriginalWord)
        
        let translatedWordRange = (foundTranslatedWord as NSString).range(of: foundTranslatedWord)
        let originalWordRange = (foundOriginalWord as NSString).range(of: foundOriginalWord)
        
        translatedAttString.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.1732688546, green: 0.7682885528, blue: 0.6751055121, alpha: 1) , range: translatedWordRange)
        translatedAttString.addAttribute(.font, value: UIFont.systemFont(ofSize: 38, weight: .regular),range: translatedWordRange)
        
        originalAttString.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1) , range: originalWordRange)
        originalAttString.addAttribute(.font, value: UIFont.systemFont(ofSize: 18, weight: .regular), range: originalWordRange)
        
        return translatedAttString + NSAttributedString(string:"\n") + originalAttString
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
