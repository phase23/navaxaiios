//
//  SpeechManager.swift
//  Xcape
//
//  Created by Wilson Jno-Baptiste on 1/29/24.
//

import AVFoundation

class SpeechManager {
    static let shared = SpeechManager()  // Singleton instance
    private let speechSynthesizer = AVSpeechSynthesizer()

    private init() {}  // Private initializer to ensure singleton usage

    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
}

