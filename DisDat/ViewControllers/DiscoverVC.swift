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

class DiscoverVC: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var noCameraPermissions = false
    
    var screenHeight: CGFloat?
    
    var rootLanguage: String!
    var learningLanguage: String!
    
    var lastClassificationRequestSent = Date()
    var lastClassificationPerformed = Date()
    
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
    
    var currentPixelBuffer: CVImageBuffer?
    
    var recognitionThreshold : Float = 0.90
    
    var debug = false
    var superDebug = false
    
    @IBOutlet weak var thresholdLabel: UILabel!
    @IBOutlet weak var thresholdSlider: UISlider!
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var resultView: UILabel!
    @IBOutlet weak var translatedResultView: UILabel!
    
    @IBOutlet weak var debugResultView: UITextView!
    @IBOutlet weak var debugFpsView: UILabel!
    @IBOutlet weak var debugImageView: UIImageView!
    
    @IBAction func enableDebug(_ sender: UITapGestureRecognizer) {
        debugFpsView.text = nil
        debugResultView.text = nil
        
        debug = !debug
        debugFpsView.isHidden = !debug
        debugResultView.isHidden = !debug
        debugImageView.isHidden = !debug
    }
    
    @IBAction func enableSuperDebug(_ sender: UITapGestureRecognizer) {
        superDebug = !superDebug
        thresholdLabel.isHidden = !superDebug
        thresholdSlider.isHidden = !superDebug
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
        if Date().timeIntervalSince(lastClassificationRequestSent)>0.5 {
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
        
        if debug {
            DispatchQueue.main.async {
                let lastClassificationTime = Date().timeIntervalSince(self.lastClassificationPerformed)*1000
                self.debugResultView.text = fullClassificationList[0...5].joined(separator:"\n")
                self.debugFpsView.text = String(format: "%.2f ms", lastClassificationTime)
                
                if let currentBuffer = self.currentPixelBuffer{
                    self.debugImageView.image = self.convert(cmage: CIImage(cvPixelBuffer: currentBuffer), crop: true)
                }
                self.lastClassificationPerformed = Date()
            }
        }
        
        print("foreground: \(fullClassificationList[0...5])")
        
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
            
            let foundTranslatedWord = String(learnedLanguageClassifications.split(separator: "\n")[0])
            let foundOriginalWord = String(rootLanguageClassifications.split(separator: "\n")[0])
            let foundEnglishWord = classificationsList[0]
            
            if let currentBuffer = self.currentPixelBuffer{
                let ciImage = CIImage(cvPixelBuffer: currentBuffer)
                self.currentPixelBuffer = nil
                let image = self.convert(cmage: ciImage, crop: true)
                
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let filePath = "\(paths[0])/\(classificationsList[0]).png"
                
                // Save image.
                try? UIImagePNGRepresentation(image)?.write(to: URL(fileURLWithPath: filePath))
                
                displayFoundWordPopup(learnedLanguageClassifications, foundTranslatedWord, foundOriginalWord, foundEnglishWord, image, fullClassificationList, discoveredIndex!)
            }
            return
        }
        else {
            self.currentPixelBuffer = nil
        }
    }
    
    fileprivate func displayFoundWordPopup(_ learnedLanguageClassifications: String, _ foundTranslatedWord: String, _ foundOriginalWord: String, _ foundEngishWord: String,  _ image: UIImage, _ fullPredictions: [String], _ discoveredIndex: Int) {
        
        let rootCategory = DiscoveredWordCollection.getInstance()!.getRootCategory(word: foundOriginalWord)
        let translatedCategory = DiscoveredWordCollection.getInstance()!.getLearningCategory(word: foundTranslatedWord)
        
        let alert = PopupDialog(title:NSLocalizedString("You found a new word in the category\n\(translatedCategory) (\(rootCategory))",comment:""), message:"\(foundTranslatedWord)\(screenHeight! > 568 ? "\n" : " ")(\(foundOriginalWord))", image: image, gestureDismissal: false)
        
        
        if let alertVC = alert.viewController as? PopupDialogDefaultViewController{

            alertVC.messageFont = UIFont.systemFont(ofSize: screenHeight! > 568 ? 18 : 16, weight: .semibold)
            alertVC.messageColor = #colorLiteral(red: 0.1921568662, green: 0.007843137719, blue: 0.09019608051, alpha: 1)
        }
        
        alert.addButton(DefaultButton(title: NSLocalizedString("Great!",comment:"")){
            DiscoveredWordCollection.getInstance()!.discovered(index: discoveredIndex)
            self.session.startRunning()
        })
        
        alert.addButton(DefaultButton(title: NSLocalizedString("This is wrong.", comment: "Wrong detection")){
            if let currentUser = Auth.auth().currentUser {
                let uploadAlert = PopupDialog(title:NSLocalizedString("I was wrong... 🤓",comment:""), message:NSLocalizedString("Do you want to report this to my creators? This means a human might look at your image and investigate.", comment:""), image: image, gestureDismissal: false)
                uploadAlert.addButton(DefaultButton(title: NSLocalizedString("Yes", comment:"")){
                    
                    let userID = currentUser.isAnonymous ? currentUser.uid : currentUser.email ?? "unknown"
                    let filename = "\(userID)-\(Date.timeIntervalSinceReferenceDate)"
                    
                    let storage = Storage.storage()
                    let storageRef = storage.reference()
                    let imageRef = storageRef.child("false_positives").child(foundEngishWord).child(filename+".png")
                    let txtRef = storageRef.child("false_positives").child(foundEngishWord).child(filename+".json")
                    
                    let data = UIImageJPEGRepresentation(image.resize(toWidth: 300)!, 0.8)!
                    
                    let metaData: [String:Any] = ["predictions":Array(fullPredictions[0...10]),
                                                  "device":UIDevice.current.model,
                                                  "orientation":Helpers.getOrientationString(),
                                                  "OS version":UIDevice.current.systemVersion,
                                                  "Battery level":UIDevice.current.batteryLevel]
                    
                    let fileURL = self.getTempURL(fileName: "metadata_temp.json")
                    self.session.startRunning()
                    
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
        case "DisDat-v7":
            return disdatkerasv7().model
        default:
            return disdatkerasv7().model
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
