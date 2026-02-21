//
//  SpeechManager.swift
//  LearningSound
//
//  Created by 윤지희 on 2/6/26.
//
import SwiftUI
import Combine
import Foundation
import Speech // to STT
import AVFoundation
import Accelerate // [핵심] 애플의 고속 수학 계산 라이브러리

// 데이터를 담을 구조체 (크기와 높낮이 정보를 동시에 가짐)
struct AudioSample: Identifiable {
    let id = UUID()
    let magnitude: Float // 소리 크기 (그래프 높이)
    let frequency: Double // 주파수/높낮이 (그래프 색상)
}

class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    private var synthesizer = AVSpeechSynthesizer()
    private let audioEngine = AVAudioEngine()
    
    @Published var myData: [AudioSample] = []
    @Published var isRecording = false
    @Published var isPlayingRecorded = false
    @Published var isPlayingReference = false
    
    private var audioPlayer: AVAudioPlayer?
    private var audioFile: AVAudioFile?
    var recordingURL: URL?
    
    @Published var targetData: [AudioSample] = []
    private var onSynthesisFinished: (([AudioSample]) -> Void)?
    
    
    override init() {
        super.init()
        let tempDir = FileManager.default.temporaryDirectory
        self.recordingURL = tempDir.appendingPathComponent("myVoice.m4a")
        self.synthesizer.delegate = self
    }
    
    
    
    private func setAudioSession(isRecording: Bool){
        let session = AVAudioSession.sharedInstance()
        do{
            if isRecording {
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            } else {
                try session.setCategory(.playback, mode: .default)
            }
            try session.setActive(true)
        } catch {
            print("fail to set audio session: \(error)")
        }
    }
    
    func startRecording() {
        setAudioSession(isRecording: true)
        myData.removeAll()
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        if let url = self.recordingURL {
            self.audioFile = try? AVAudioFile(forWriting: url, settings: format.settings)
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { (buffer, when) in
            self.analyze(buffer: buffer)
            try? self.audioFile?.write(from: buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        isRecording = true
    }
    
    func playRecording(){
        guard let url = recordingURL else {return}
        do {
            setAudioSession(isRecording: false)
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            DispatchQueue.main.async{self.isPlayingRecorded = true}
        } catch {
            print("fail to play audio: \(error)")
        }
    }
    
    func playReference(text: String, language: String) {
        setAudioSession(isRecording: false)
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.4
        
        synthesizer.delegate = self
        synthesizer.speak(utterance)
        DispatchQueue.main.async {self.isPlayingReference = true}
    }
    
    
    func stopRecording() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        audioFile = nil
        isRecording = false
    }
    
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    // [핵심] 오디오 데이터를 분석하는 함수
    private func analyze(buffer: AVAudioPCMBuffer) {
        guard let sample = extractPitch(from: buffer) else { return }
        
        DispatchQueue.main.async {
            // 소리가 너무 작으면(잡음) 분석 안 함
            if sample.magnitude > 1.5 { // 잡음 필터 상향 0.5 -> 1.5
                self.myData.append(sample)
                if self.myData.count > 50 { self.myData.removeFirst() }
            }
        }
    }
    
    private func extractPitch(from buffer: AVAudioPCMBuffer) -> AudioSample? {
        guard let channelData = buffer.floatChannelData?[0] else { return nil }
        let length = Int(buffer.frameLength)
        guard length>0 else { return nil }
        
        //볼륨
        let rms = sqrt(stride(from:0, to:length, by:1).map {pow(channelData[$0], 2)}.reduce(0, +)/Float(length))
        
        //피치 - 제로 크로싱(Zero Crossing) 방식 (가벼운 버전)
        // (진짜 정밀한 FFT는 코드가 너무 길어져서, 학생 수준에서 충분한 제로 크로싱을 사용)
        var zeroCrossings = 0
        for i in 1..<length {
            if (channelData[i-1] > 0 && channelData[i] <= 0) || (channelData[i-1] <= 0 && channelData[i] > 0) {
                zeroCrossings += 1
            }
        }
        
        // 제로 크로싱 횟수를 주파수로 대략 변환
        let frequency = Double(zeroCrossings) / (Double(length) / Double(buffer.format.sampleRate)) / 2.0
        return AudioSample(magnitude: rms*50, frequency: frequency)
        
    }
    
    func createReference(text: String, language: String = "en-US") {
        synthesizer = AVSpeechSynthesizer()
        self.targetData.removeAll()
    
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.4
        
        synthesizer.write(utterance) { buffer in
            guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {return}
            if let sample = self.extractPitch(from: pcmBuffer){
                DispatchQueue.main.async{
                    self.targetData.append(sample)
                }
            }
        }
    }
    
    func pearsonScore() -> Double {
        let targetFreqs = targetData.map { $0.frequency }
        let myFreqs = myData.map { $0.frequency }
        let normTarget = normalize(targetFreqs)
        let normMy = normalize(myFreqs)
        
        guard targetFreqs.count>1, myFreqs.count>1 else {return 0}
        
        let resampledTarget = resample(normTarget, to:100)
        let resampledMy = resample(normMy, to:100)
        
        let correlation = pearsonCorrelation(x: resampledTarget, y: resampledMy)
        var intonationScore = 0.0
        if correlation>0 {
            intonationScore = correlation*100
        } else {
            intonationScore = 0
        }
        return intonationScore
    }
    
    private func normalize(_ data:[Double]) -> [Double] {
        guard let minVal = data.min(), let maxVal = data.max(), maxVal>minVal else {return data}
        let range = maxVal - minVal
        return data.map{($0-minVal)/range}
    }
    
    private func resample(_ data: [Double], to targetCount: Int)->[Double]{
        guard !data.isEmpty else {return []}
        var result: [Double] = []
        for i in 0..<targetCount {
            let index = Double(i)*Double(data.count-1)/Double(targetCount-1)
            let lowerIndex = Int(floor(index))
            let upperIndex = min(lowerIndex+1, data.count-1)
            let weight = index - Double(lowerIndex)
            
            //선형보간법
            result.append(data[lowerIndex]*(1-weight)+data[upperIndex]*weight)
        }
        return result
    }
    
    private func pearsonCorrelation(x: [Double], y: [Double]) -> Double {
        //선형 보간 제대로 안됐으면 비교 불가
        guard x.count == y.count, x.count>0 else { return 0.0 }
        
        let n = Double(x.count)
        let meanX = x.reduce(0, +)/n // 타켓 그래프의 평균값
        let meanY = y.reduce(0, +)/n
        
        var numerator = 0.0
        var denomX = 0.0
        var denomY = 0.0
        
        for i in 0..<x.count {
            let diffX = x[i]-meanX
            let diffY = y[i]-meanY
            numerator += diffX*diffY
            denomX += diffX*diffX
            denomY += diffY*diffY
        }
        if denomX==0 || denomY==0 {return 0.0}
        return numerator/sqrt(denomX*denomY)
    }
    
    func sttScore(audioURL: URL, targetText: String, languageCode: String, completion: @escaping(Double) -> Void) {
        var localeIdentifier = "en-US"
        if languageCode.hasPrefix("ko"){
            localeIdentifier = "ko-KR"
        } else if languageCode.hasPrefix("zh"){
            localeIdentifier = "zh-CN"
        } else if languageCode.hasPrefix("en"){
            localeIdentifier = "en-US"
        } else {
            localeIdentifier = languageCode
        }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)), recognizer.isAvailable else {
            print("음성 인식을 사용할 수 없습니다. (언어: \(localeIdentifier))")
            completion(0.0)
            return
        }
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        recognizer.recognitionTask(with: request) { result, error in
            if let error = error {
                print("STT 에러 발생: \(error.localizedDescription)")
                completion(0.0)
                return
            }
            guard let result = result else {return}
            
            if result.isFinal {
                let recognizedText = result.bestTranscription.formattedString
                print("[\(localeIdentifier)] 내가 말한 문장: \(recognizedText)")
                let matchScore = self.textSimilarity(target: targetText, recognized: recognizedText)
                completion(matchScore)
            }
        }
    }
    
    private func textSimilarity(target: String, recognized: String) -> Double {
        let targetWords = target.lowercased().components(separatedBy: .punctuationCharacters).joined().split(separator: " ")
        let recognizedWords = recognized.lowercased().components(separatedBy: .punctuationCharacters).joined().split(separator: " ")
        guard !targetWords.isEmpty else {return 0.0}
        var matchCount = 0
        for word in recognizedWords {
            if targetWords.contains(word) {
                matchCount += 1
            }
        }
        let ratio = Double(matchCount)/Double(targetWords.count)
        return min(ratio*100, 100.0)
    }
    
    func audioPlayerDidFinishPlaying(_ play: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlayingRecorded = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance){
        DispatchQueue.main.async {
            self.isPlayingReference = false
        }
    }

}


