//
//  ViewController.swift
//  VisionSample
//
//  Created by chris on 19/06/2017.
//  Copyright © 2017 MRM Brand Ltd. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class TranslateViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var rootLanguage = "en";
    var learningLanguage = "fr";
    
    var lastForegroundCheck = Date()
    var lastBackgroundCheck = Date()

    var englishLabelDict: [String:Int] = [:]
    var rootLanguageLabels: [String] = []
    var learningLanguageLabels: [String] = []
    
    var englishBackgroundLabelDict: [String:Int] = [:]
    var rootLanguageBackgroundLabels: [String] = []
    var learningLanguageBackgroundLabels: [String] = []

    
    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    let captureQueue = DispatchQueue(label: "captureQueue")
    var gradientLayer: CAGradientLayer!
    var visionRequests = [VNRequest]()
    var backgroundVisionRequests = [VNRequest]()
    var modelName = "DisDat-v4"
    
    var recognitionThreshold : Float = 0.25
    
    @IBOutlet weak var thresholdStackView: UIStackView!
    @IBOutlet weak var thresholdLabel: UILabel!
    @IBOutlet weak var thresholdSlider: UISlider!
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var resultView: UILabel!
    @IBOutlet weak var translatedResultView: UILabel!
    @IBOutlet weak var resultBackgroundView: UILabel!
    @IBOutlet weak var translatedResultBackgroundView: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        let englishLabels = Helpers.arrayFromContentsOfFileWithName(fileName: "labels_en")!
        englishLabelDict = Helpers.arrayToReverseDictionary(englishLabels)
        rootLanguageLabels = Helpers.arrayFromContentsOfFileWithName(fileName: "labels_\(rootLanguage)")!
        learningLanguageLabels = Helpers.arrayFromContentsOfFileWithName(fileName: "labels_\(learningLanguage)")!
        
        let englishBackgroundLabels = Helpers.arrayFromContentsOfFileWithName(fileName: "labels_bg_en")!.map({$0.replacingOccurrences(of: " ", with: "_")})
        englishBackgroundLabelDict = Helpers.arrayToReverseDictionary(englishBackgroundLabels)
        rootLanguageBackgroundLabels = Helpers.arrayFromContentsOfFileWithName(fileName: "labels_bg_\(rootLanguage)")!
        learningLanguageBackgroundLabels = Helpers.arrayFromContentsOfFileWithName(fileName: "labels_bg_\(learningLanguage)")!

        // get hold of the default video camera
        guard let camera = AVCaptureDevice.default(for: .video) else {
            fatalError("No video camera available")
        }
        do {
            // add the preview layer
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewView.layer.addSublayer(previewLayer)
            // add a slight gradient overlay so we can read the results easily
            gradientLayer = CAGradientLayer()
            gradientLayer.colors = [
                UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.7).cgColor,
                UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.0).cgColor,
            ]
            gradientLayer.locations = [0.0, 0.3]
            self.previewView.layer.addSublayer(gradientLayer)
            
            // create the capture input and the video output
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: captureQueue)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            session.sessionPreset = .high
            
            // wire up the session
            session.addInput(cameraInput)
            session.addOutput(videoOutput)
            
            // make sure we are in portrait mode
            let conn = videoOutput.connection(with: .video)
            conn?.videoOrientation = .portrait
            
            // Start the session
            session.startRunning()
            
            // set up the vision model
            guard let model = try? VNCoreMLModel(for: getModel(name:modelName)) else {
                fatalError("Could not load model")
            }
            // set up the request using our vision model
            let classificationRequest = VNCoreMLRequest(model: model, completionHandler: handleClassifications)
            classificationRequest.imageCropAndScaleOption = .centerCrop
            visionRequests = [classificationRequest]

            guard let backgroundModel = try? VNCoreMLModel(for: GoogLeNetPlaces().model) else {
                fatalError("Could not load model")
            }
            // set up the request using our vision model
            let backgroundclassificationRequest = VNCoreMLRequest(model: backgroundModel, completionHandler: handleClassificationBackground)
            backgroundclassificationRequest.imageCropAndScaleOption = .centerCrop
            backgroundVisionRequests = [backgroundclassificationRequest]
        } catch {
            fatalError(error.localizedDescription)
        }
        
        updateThreshholdLabel()
    }
    
    func updateThreshholdLabel () {
        self.thresholdLabel.text = "Threshold: " + String(format: "%.2f", recognitionThreshold)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = self.previewView.bounds;
        gradientLayer.frame = self.previewView.bounds;
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
                try imageRequestHandler.perform(self.visionRequests)
            } catch {
                print(error)
            }
        }/*
        else if Date().timeIntervalSince(lastBackgroundCheck)>0.5 {
            lastBackgroundCheck = Date()
            connection.videoOrientation = .portrait
            
            var requestOptions:[VNImageOption: Any] = [:]
            
            if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
                requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
            }
            
            // for orientation see kCGImagePropertyOrientation
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored, options: requestOptions)
            do {
                try imageRequestHandler.perform(self.backgroundVisionRequests)
            } catch {
                print(error)
            }
        }*/

    }
    
    @IBAction func userTapped(sender: Any) {
        self.thresholdStackView.isHidden = !self.thresholdStackView.isHidden
    }
    
    @IBAction func sliderValueChanged(slider: UISlider) {
        self.recognitionThreshold = slider.value
        updateThreshholdLabel()
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
        if !classificationsList.isEmpty{
            print("foreground: \(classificationsList[0])")
        }

        
        let rootLanguageClassifications = classificationsList.map( {englishLabelDict[$0] != nil ?rootLanguageLabels[englishLabelDict[$0]!]:$0}).joined(separator:"\n")
        let learnedLanguageClassifications = classificationsList.map( {englishLabelDict[$0] != nil ?learningLanguageLabels[englishLabelDict[$0]!]:""}).joined(separator:"\n")
        
        DispatchQueue.main.async {
            self.resultView.text = rootLanguageClassifications
            self.translatedResultView.text = learnedLanguageClassifications
        }
    }
    
    func handleClassificationBackground(request: VNRequest, error: Error?) {
        if let theError = error {
            print("Error: \(theError.localizedDescription)")
            return
        }
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        let classification = (observations[0] as? VNClassificationObservation)
            .flatMap({$0.confidence > recognitionThreshold ? $0 : nil})
            .map({$0.identifier})
        print("background: \(classification ?? "")")
        
        var rootLanguageClassification = ""
        var learnedLanguageClassification = ""
        
        if classification != nil, let backgroundIndex = englishBackgroundLabelDict[classification!] {
            rootLanguageClassification = rootLanguageBackgroundLabels[backgroundIndex]
            learnedLanguageClassification = learningLanguageBackgroundLabels[backgroundIndex]
        }

        DispatchQueue.main.async {
            self.resultBackgroundView.text = rootLanguageClassification
            self.translatedResultBackgroundView.text = learnedLanguageClassification
        }
    }
    
    func getModel(name: String) -> MLModel{
        switch modelName {
        case "VGG16-keras":
            return vgg16keras().model
        case "VGG16":
            return VGG16().model
        case "DisDat-v4":
            return disdatkerasv4().model
        default:
            return disdatkerasv4().model
        }
    }
}

