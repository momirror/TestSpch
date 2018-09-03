//
//  STTService.swift
//  SpeechDemo
//
//  Created by momirror on 2018/9/3.
//  Copyright © 2018年 oeasy. All rights reserved.
//

import UIKit
import Speech

protocol STTServiceDelegate: class {
    func speechToTextResult(content:String,isFinal:Bool);
    func speechToTextError(error:Error?);
    func availabilityDidChange(avalible:Bool);
}

class STTService: NSObject,SFSpeechRecognizerDelegate {
    
    static let shareInstance = STTService()
    private var speechRecognizer:SFSpeechRecognizer!
    weak var delegate:STTServiceDelegate?
    var isEnable = false
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine:AVAudioEngine?
    
    var locale:Locale? {
        willSet(newValue){
            speechRecognizer = SFSpeechRecognizer(locale: newValue!)
        }
    }
    
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
            
            if self.delegate != nil {
                self.delegate?.availabilityDidChange(avalible: self.isEnable)
            }
            
        }
    }
    
    func isRunning() -> Bool {
        return (audioEngine?.isRunning)!
    }
    
    func startSpeaking() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        if recognitionRequest == nil {
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            recognitionRequest?.shouldReportPartialResults = true
        }
        
        let audioSession = AVAudioSession.sharedInstance()
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
        
        
        self.recognitionTask = self.speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: {[unowned self] (result, error) in
            
            var isFinal = false
            
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
                
                if self.delegate != nil && error != nil {
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
        if delegate != nil {
            delegate?.availabilityDidChange(avalible: available)
        }
    }
    
    deinit {
        print("STTService deinit")
    }
}
