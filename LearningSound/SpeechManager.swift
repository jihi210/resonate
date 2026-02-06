//
//  SpeechManager.swift
//  LearningSound
//
//  Created by 윤지희 on 2/6/26.
//
import SwiftUI
import Combine
import Foundation
import Speech
import AVFoundation
import Accelerate // [핵심] 애플의 고속 수학 계산 라이브러리

// 데이터를 담을 구조체 (크기와 높낮이 정보를 동시에 가짐)
struct AudioSample: Identifiable {
    let id = UUID()
    let magnitude: Float // 소리 크기 (그래프 높이)
    let frequency: Float // 주파수/높낮이 (그래프 색상)
}

class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private var synthesizer = AVSpeechSynthesizer()
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioFile: AVAudioFile?
    private var audioPlayer: AVAudioPlayer?
    private var recordingURL: URL?
    private var synthesisCompletion: (([AudioSample]) -> Void)?
    private var tempReferenceSamples: [AudioSample] = []
    
    override init() {
        super.init()
        let tempDir = FileManager.default.temporaryDirectory
        self.recordingURL = tempDir.appendingPathComponent("myVoice.m4a")
    }
    
    @Published var transcript: String = ""
    @Published var audioSamples: [AudioSample] = [] // 데이터 배열 변경
    @Published var isRecording = false
    
    func startRecording() {
        self.audioSamples.removeAll()
        stopRecording() // 기존 녹음 중지
        
        // 오디오 세션 설정
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try? audioSession.setActive(true)
        
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }
        request.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        if let url = self.recordingURL {
            self.audioFile = try? AVAudioFile(forWriting: url, settings: recordingFormat.settings)
        }
        // 버퍼 사이즈 1024 (분석 속도를 위해 적절한 값)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            request.append(buffer)
            self.processAudioBuffer(buffer: buffer)
            try? self.audioFile?.write(from: buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }
            if error != nil {
                self.stopRecording()
            }
        }
        isRecording = true
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()
        isRecording = false
        
        audioFile = nil
    }
    
    func playRecording(){
        guard let url = recordingURL else {return}
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("재생 실패: \(error)")
        }
    }
    
    // [핵심] 오디오 데이터를 분석하는 함수
    private func processAudioBuffer(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        
        // 1. 소리 크기(RMS) 계산
        var totalSquared: Float = 0
        for i in 0..<frameLength {
            totalSquared += channelData[i] * channelData[i]
        }
        let rms = sqrt(totalSquared / Float(frameLength))
        
        // 2. 소리 높낮이(Pitch) 계산 - 제로 크로싱(Zero Crossing) 방식 (가벼운 버전)
        // (진짜 정밀한 FFT는 코드가 너무 길어져서, 학생 수준에서 충분한 제로 크로싱을 사용)
        var zeroCrossings = 0
        for i in 1..<frameLength {
            if (channelData[i-1] > 0 && channelData[i] <= 0) || (channelData[i-1] <= 0 && channelData[i] > 0) {
                zeroCrossings += 1
            }
        }
        
        // 제로 크로싱 횟수를 주파수로 대략 변환
        let frequency = Float(zeroCrossings) / (Float(frameLength) / Float(buffer.format.sampleRate)) / 2.0
        
        // UI 업데이트
        DispatchQueue.main.async {
            // 소리가 너무 작으면(잡음) 분석 안 함
            if rms > 0.01 {
                let newSample = AudioSample(magnitude: rms * 50, frequency: frequency)
                self.audioSamples.append(newSample)
                
                // 최근 40개 데이터만 유지 (화면 밖으로 나가는 거 삭제)
                if self.audioSamples.count > 40 {
                    self.audioSamples.removeFirst()
                }
            }
        }
    }
    
    func generateReferenceData(text: String, language: String = "en-US", completion: @escaping ([AudioSample]) -> Void) {
        self.synthesizer = AVSpeechSynthesizer()
        self.synthesizer.delegate = self
        self.synthesisCompletion = completion
        self.tempReferenceSamples = []
        let utterance = AVSpeechUtterance(string: text)
        
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.4
        
        synthesizer.write(utterance) { [weak self] (buffer: AVAudioBuffer) in
            guard let self = self, let pcmBuffer = buffer as? AVAudioPCMBuffer else {return}
            if let sample = self.analyzeBufferSingle(buffer: pcmBuffer){
                self.tempReferenceSamples.append(sample)
            }
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async{
            self.synthesisCompletion?(self.tempReferenceSamples)
            self.synthesisCompletion = nil
        }
    }
    
    private func analyzeBufferSingle(buffer: AVAudioPCMBuffer) -> AudioSample? {
        guard let channelData = buffer.floatChannelData?[0] else {return nil}
        let frameLength = Int(buffer.frameLength)
        guard frameLength>1 else {return nil}
        
        var totalSquared: Float = 0
        for i in 0..<frameLength { totalSquared += channelData[i]*channelData[i] }
        let rms = sqrt(totalSquared/Float(frameLength))
        
        var zeroCrossings = 0
        for i in 1..<frameLength {
            if (channelData[i-1]>0 && channelData[i]<=0) {
                zeroCrossings += 1
            }
        }
        let frequency = Float(zeroCrossings) / (Float(frameLength) / Float(buffer.format.sampleRate))
        return rms>0.01 ? AudioSample(magnitude: rms, frequency: frequency) : nil
    }
}

