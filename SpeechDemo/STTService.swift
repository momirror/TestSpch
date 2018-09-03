//
//  STTService.swift
//  SpeechDemo
//
//  Created by momirror on 2018/9/3.
//  Copyright © 2018年 oeasy. All rights reserved.
//

import UIKit
import Speech

protocol STTServiceDelegate {
    func speechToTextResult(content:String,isFinal:Bool);
    func speechToTextError(error:Error?);
}

class STTService: NSObject,SFSpeechRecognizerDelegate {
    
    static let shareInstance = STTService()
    private var speechRecognizer:SFSpeechRecognizer!
    
    var delegate:STTServiceDelegate?
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine:AVAudioEngine?
    private var locale:Locale? {
        willSet(newValue){
            speechRecognizer = SFSpeechRecognizer(locale: newValue!)
        }
    }
    
    
    var isEnable = false
    
    private override init() {
        super.init()
        locale = Locale(identifier: "en-US") // use en default
        speechRecognizer = SFSpeechRecognizer(locale: locale!)
        audioEngine =  AVAudioEngine()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true  //6
        
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            self.isEnable = authStatus == .authorized
        }
    }
    
    
    func startSpeaking() {
        
        if recognitionTask != nil {  //1
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        
        
        guard let inputNode = audioEngine?.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in  //7
            
            var isFinal = false  //8
            
            if result != nil {
                
                isFinal = (result?.isFinal)!
                if self.delegate != nil {
                    self.delegate?.speechToTextResult(content: (result?.bestTranscription.formattedString)!, isFinal: (result?.isFinal)!)
                }
            }
            
            if error != nil || isFinal {
                self.audioEngine?.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                if self.delegate != nil {
                    self.delegate?.speechToTextError(error: error)
                }
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine?.prepare()
        
        do {
            try audioEngine?.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
    }
    
    func stopSpeaking()  {
        audioEngine?.stop()
        recognitionRequest?.endAudio()
    }
    

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        isEnable = available
    }
}
