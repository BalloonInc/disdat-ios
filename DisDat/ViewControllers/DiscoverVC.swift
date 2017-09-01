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

class DiscoverVC: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var noCameraPermissions = false
    
    var rootLanguage: String!
    var learningLanguage: String!
    
    var lastForegroundCheck = Date()
    
    var englishLabelDict: [String:Int] = [:]
    
    var rootLanguageLabels: [String] = []
    var learningLanguageLabels: [String] = []
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    let captureQueue = DispatchQueue(label: "captureQueue")
    var gradientLayer: CAGradientLayer?
    var visionRequests = [VNRequest]()
    var modelName = "DisDat-v7"
    var paused = false
    
    var popupRect: CGRect?
    
    var currentPixelBuffer: CVImageBuffer?
    
    var recognitionThreshold : Float = 0.90
    
    @IBOutlet weak var thresholdLabel: UILabel!
    @IBOutlet weak var thresholdSlider: UISlider!
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var resultView: UILabel!
    @IBOutlet weak var translatedResultView: UILabel!
    
    @IBAction func enableDebug(_ sender: UITapGestureRecognizer) {
    }
    
    @IBAction func enableSuperDebug(_ sender: UITapGestureRecognizer) {
        self.thresholdLabel.isHidden = !self.thresholdLabel.isHidden
        self.thresholdSlider.isHidden = !self.thresholdSlider.isHidden
    }
    
    @IBAction func sliderValueChanged(slider: UISlider) {
        self.recognitionThreshold = slider.value
        updateThresholdLabel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rootLanguage = Authentication.getInstance().currentRootLanguage!
        learningLanguage = Authentication.getInstance().currentLearningLanguage!
        
        englishLabelDict = DiscoveredWordCollection.getInstance()!.englishLabelDict
        
        rootLanguageLabels = DiscoveredWordCollection.getInstance()!.rootLanguageWords
        learningLanguageLabels = DiscoveredWordCollection.getInstance()!.learningLanguageWords
        
        loadCameraAndRequests()
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
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.session.isRunning{
                self.session.startRunning()
            }
        }
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
        // get hold of the default video camera
        let camera = AVCaptureDevice.default(for: .video)
        
        if camera == nil {
            showCameraPermissionsError()
            print("error - no camera 1")
            return
        }
        
        do {
            // add the preview layer
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
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
    
    func updateThresholdLabel () {
        self.thresholdLabel.text = "Threshold: " + String(format: "%.2f", recognitionThreshold)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.previewView != nil {
            previewLayer?.frame = self.previewView.bounds;
            gradientLayer?.frame = self.previewView.bounds;
        }
        
        let origin = CGPoint(x: 0, y: 0)
        let size = CGSize(width: self.view.frame.width*0.9*UIScreen.main.scale, height: self.view.frame.height*0.6*UIScreen.main.scale)
        popupRect = CGRect(origin: origin, size: size)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        if Date().timeIntervalSince(lastForegroundCheck)>0.5 {
            lastForegroundCheck = Date()
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
    
    fileprivate func displayFoundWordPopup(_ learnedLanguageClassifications: String, _ foundTranslatedWord: String, _ foundOriginalWord: String, _ image: UIImage) {
        
        let rootCategory = DiscoveredWordCollection.getInstance()!.getRootCategory(word: foundOriginalWord)
        let translatedCategory = DiscoveredWordCollection.getInstance()!.getLearningCategory(word: foundTranslatedWord)
        
        let alert = PopupDialog(title:NSLocalizedString("You found a new word in the category\n\(translatedCategory) (\(rootCategory))",comment:""), message:"\(foundTranslatedWord)\n (\(foundOriginalWord))", image: image, buttonAlignment: .horizontal , gestureDismissal: false)
        
        if let alertVC = alert.viewController as? PopupDialogDefaultViewController{
            alertVC.messageFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
            alertVC.messageColor = #colorLiteral(red: 0.1921568662, green: 0.007843137719, blue: 0.09019608051, alpha: 1)
        }
        
        alert.addButton(DefaultButton(title: NSLocalizedString("Great!",comment:"")){
            self.session.startRunning()
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
        //            .map({"\($0.identifier) \($0.confidence)"})
        if !classificationsList.isEmpty{
            print("foreground: \(observations[0...10].flatMap({ $0 as? VNClassificationObservation }).map({"\($0.identifier) \($0.confidence)"}))")
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
        
        let discoveredIndex = englishLabelDict[classificationsList[0]]
        if !DiscoveredWordCollection.getInstance()!.isDiscovered(index: discoveredIndex!){
            session.stopRunning()
            DiscoveredWordCollection.getInstance()!.discovered(index: discoveredIndex!)
            
            let foundTranslatedWord = String(learnedLanguageClassifications.split(separator: "\n")[0])
            let foundOriginalWord = String(rootLanguageClassifications.split(separator: "\n")[0])
            
            if let currentBuffer = self.currentPixelBuffer{
                let ciImage = CIImage(cvPixelBuffer: currentBuffer).cropped(to: popupRect!)
                self.currentPixelBuffer = nil
                let image = self.convert(cmage: ciImage)
                
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let filePath = "\(paths[0])/\(classificationsList[0]).png"
                
                // Save image.
                try? UIImagePNGRepresentation(image)?.write(to: URL(fileURLWithPath: filePath))
                
                displayFoundWordPopup(learnedLanguageClassifications, foundTranslatedWord, foundOriginalWord, image)
            }
            return
        }
    }
    
    func getModel(name: String) -> MLModel{
        switch modelName {
        case "DisDat-v7":
            return disdatkerasv7().model
        default:
            return disdatkerasv7().model
        }
    }
    
    func convert(cmage:CIImage) -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
}
