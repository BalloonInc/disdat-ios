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

class TranslateVC: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var rootLanguage = "en";
    var learningLanguage = "fr";
    
    var lastForegroundCheck = Date()

    var englishLabelDict: [String:Int] = [:]
    var rootLanguageLabels: [String] = []
    var learningLanguageLabels: [String] = []
    
    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    let captureQueue = DispatchQueue(label: "captureQueue")
    var gradientLayer: CAGradientLayer!
    var visionRequests = [VNRequest]()
    var modelName = "DisDat-v7"
    var paused = false
    
    var recognitionThreshold : Float = 0.80
    
    @IBOutlet weak var thresholdLabel: UILabel!
    @IBOutlet weak var thresholdSlider: UISlider!
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var resultView: UILabel!
    @IBOutlet weak var translatedResultView: UILabel!
    
    @IBAction func liveTrackSwitchFlipped(_ sender: UISwitch) {
        paused = !sender.isOn
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultView.text=nil
        translatedResultView.text=nil
        
        let englishLabels = Helpers.arrayFromContentsOfFileWithName(fileName: "labels_en")!
        englishLabelDict = Helpers.arrayToReverseDictionary(englishLabels)
        rootLanguageLabels = Helpers.arrayFromContentsOfFileWithName(fileName: "labels_\(rootLanguage)")!
        learningLanguageLabels = Helpers.arrayFromContentsOfFileWithName(fileName: "labels_\(learningLanguage)")!
        
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

        } catch {
            fatalError(error.localizedDescription)
        }
        
        updateThresholdLabel()
    }
    
    func updateThresholdLabel () {
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
        }
    }
    
    @IBAction func sliderValueChanged(slider: UISlider) {
        self.recognitionThreshold = slider.value
        updateThresholdLabel()
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
        let discoveredIndex = englishLabelDict[classificationsList[0]]
        if !self.paused && !DiscoveredWordCollection.getInstance().isDiscovered(index: discoveredIndex!){
            self.paused=true
            DiscoveredWordCollection.getInstance().discovered(index: discoveredIndex!)
            DispatchQueue.main.async {
                self.resultView.text = rootLanguageClassifications
                self.translatedResultView.text = learnedLanguageClassifications
                
                let alert = UIAlertController(title: "You found a new word", message: "You just discovered '\(learnedLanguageClassifications.split(separator: "\n")[0])' (\(rootLanguageClassifications.split(separator: "\n")[0]))", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Great!", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: {self.paused=false})
            }
            return
        }
        DispatchQueue.main.async {
            self.resultView.text = rootLanguageClassifications
            self.translatedResultView.text = learnedLanguageClassifications
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
}

