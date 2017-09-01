//
//  LanguageSelectorViewController.swift
//  VisionSample
//
//  Created by Wouter Devriendt on 29/07/2017.
//  Copyright © 2017 Balloon Inc. All rights reserved.
//

import UIKit
import AVKit
import UserNotifications
import PopupDialog
import OneSignal

class LanguageSelectorVC: UIViewController {
    
    var changeLanguageOnly = false
    
    @IBOutlet weak var rootLanguagePicker: LanguageSelectionPickerView!
    @IBOutlet weak var newLanguagePicker: LanguageSelectionPickerView!
    
    @IBOutlet weak var nativeLanguageTile: UIView!
    @IBOutlet weak var learningLanguageTile: UIView!
    
    @IBOutlet weak var cameraPermissionsTile: UIView!
    
    @IBOutlet weak var pushNotificationsPermissionsTile: UIView!
    @IBOutlet weak var readyTile: UIView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var cameraAgreeButton: UIButton!
    @IBOutlet weak var cameraAgreementLabel: UILabel!
    
    @IBOutlet weak var notifcationsAgreeButton: UIButton!
    @IBOutlet weak var notificationsDeclineButton: UIButton!
    @IBOutlet weak var notificationsCheckBoxButton: UIButton!
    @IBOutlet weak var pushPermissionsLabel: UILabel!
    
    let pushDeclined = NSLocalizedString("No push notifications - no problem! If you change your mind, you can enable this in the iOS preferences for this app.", comment: "")
    
    @IBAction func cameraAgreeButtonPressed(_ sender: UIButton) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                DispatchQueue.main.async {
                    self.cameraPermissionValidated()
                }
            } else {
                DispatchQueue.main.async {
                    self.cameraAgreementLabel.text = NSLocalizedString("I really need permissions to use the camera. Please go to the settings to give them and return here afterwards.", comment: "")
                }
            }
        }
    }
    
    @IBAction func notificationsAgreeButtonPressed(_ sender: UIButton) {
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            self.notifcationsAgreeButton.isHidden = true
            self.notificationsDeclineButton.isHidden = true

            if accepted {
                self.notificationsCheckBoxButton.isHidden = false
            }
            else {
                self.pushPermissionsLabel.text = self.pushDeclined
            }
        })
    }
    
    @IBAction func notificationsDeclineButtonPressed(_ sender: UIButton) {
        self.notifcationsAgreeButton.isHidden = true
        self.notificationsDeclineButton.isHidden = true
        self.notificationsCheckBoxButton.isHidden = true
        self.pushPermissionsLabel.text = pushDeclined
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        precheckCameraPermissions()
        
        var tiles = [nativeLanguageTile, learningLanguageTile, readyTile]
        
        if !changeLanguageOnly {
            tiles.insert(cameraPermissionsTile, at: 2)
            tiles.insert(pushNotificationsPermissionsTile, at: 3)
        }
        
        for (index, tile) in tiles.enumerated() {
            setTileUI(tile: tile!, id: index+1)
        }
        
        if let patternImage = UIImage(named: "settings_bg_\(Int(arc4random_uniform(2)+1))"){
            self.scrollView.backgroundColor = UIColor(patternImage: patternImage)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.newLanguagePicker.selectRow(1, inComponent: 0, animated: false)
        self.newLanguagePicker.selectedLanguageCode = LanguageSelectionPickerView.languageKeys[1]
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        switch cameraAuthorizationStatus {
        case .denied, .notDetermined, .restricted: do {
            showCameraPermissionsError()
            return false
            }
        case .authorized: return true
        }
    }
    
    fileprivate func cameraPermissionValidated() {
        self.cameraAgreementLabel.text = NSLocalizedString("All set on camera permissions!", comment: "")
        self.cameraAgreeButton.setImage(UIImage(named:"ok"), for: .normal)
        self.cameraAgreeButton.isUserInteractionEnabled = false
    }
    
    func precheckCameraPermissions(){
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        switch cameraAuthorizationStatus {
        case .denied, .notDetermined, .restricted: return
        case .authorized: do {
            cameraPermissionValidated()
            }
        }
    }
    
    fileprivate func showCameraPermissionsError() {
        DispatchQueue.main.async {
            let alert = PopupDialog(title:NSLocalizedString("Camera permissions", comment: ""), message:NSLocalizedString("Please go to the iOS preferences for this app and allow camera access in order to be able to use the app.", comment: ""))
            
            alert.addButton(DefaultButton(title: NSLocalizedString("Go to settings", comment: "")){
                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
            })
            alert.addButton(CancelButton(title:NSLocalizedString("Cancel", comment: "")){})
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "languageSelectedSegue"){
            Authentication.getInstance().setLanguages(rootLanguage: rootLanguagePicker.selectedLanguageCode, learningLanguage: newLanguagePicker.selectedLanguageCode)
            DiscoveredWordCollection.setLanguages(rootLanguage: rootLanguagePicker.selectedLanguageCode, learningLanguage: newLanguagePicker.selectedLanguageCode)
        }
    }
    
    func setTileUI(tile: UIView, id: Int){
        tile.layer.cornerRadius = 25;
        tile.layer.masksToBounds = false;
        
        let circleView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        
        circleView.layer.cornerRadius = 25;  // half the width/height
        circleView.backgroundColor = UIColor(red: CGFloat(254.0/255), green: CGFloat(217.0/255), blue: CGFloat(77.0/255), alpha: 1.0)
        circleView.center = CGPoint(x: self.view.frame.width/2-tile.frame.origin.x, y: 0)
        
        circleView.layer.borderWidth = 4;
        circleView.layer.borderColor = UIColor.white.cgColor
        
        tile.addSubview(circleView)
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        label.text = "\(id)"
        label.textAlignment = .center
        label.center = CGPoint(x: self.view.frame.width/2-tile.frame.origin.x, y: 0)
        
        tile.addSubview(label)
    }
}
