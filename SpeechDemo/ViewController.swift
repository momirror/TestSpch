//
//  ViewController.swift
//  SpeechDemo
//
//  Created by momirror on 2018/9/3.
//  Copyright © 2018年 oeasy. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController,STTServiceDelegate {
    
    
    @IBOutlet weak var textview: UITextView!
    @IBOutlet weak var btnSpeech: UIButton!
    
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        STTService.shareInstance.delegate = self
//        STTService.shareInstance.locale = Locale(identifier: "zh-CN")
        btnSpeech.isEnabled = false
    }
    
    @IBAction func buttonResponse(_ sender: Any) {
        
        if STTService.shareInstance.isRunning() {
            btnSpeech.setTitle("Start Recording", for: .normal)
        } else {
            STTService.shareInstance.startSpeaking()
            btnSpeech.setTitle("Stop Recording", for: .normal)
        }
    }
    
    func speechToTextResult(content:String,isFinal:Bool) {
        textview.text = content
    }
    
    func speechToTextError(error:Error?) {
        
    }
    
    func availabilityDidChange(avalible: Bool) {
        
        OperationQueue.main.addOperation() {
            self.btnSpeech.isEnabled = avalible
        }
        
    }
    
   

}

