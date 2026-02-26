import SwiftUI
import Combine
import Speech
import Accelerate

struct AudioSample: Identifiable {
    let id = UUID()
    let magnitude: Float
    let frequency: Double
}

class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    private var synthesizer = AVSpeechSynthesizer()
    private let audioEngine = AVAudioEngine()
    private var recognizers: [String: SFSpeechRecognizer] = [:]
    private var voices: [String: AVSpeechSynthesisVoice] = [:]
    
    @Published var myData: [AudioSample] = []
    @Published var isRecording = false
    @Published var isPlayingRecorded = false
    @Published var isPlayingReference = false
    
    private var audioPlayer: AVAudioPlayer?
    private var audioFile: AVAudioFile?
    var recordingURL: URL?
    
    @Published var targetData: [AudioSample] = []
    
    override init() {
        super.init()
        let tempDir = FileManager.default.temporaryDirectory
        self.recordingURL = tempDir.appendingPathComponent("myVoice.m4a")
        self.synthesizer.delegate = self
        
        DispatchQueue.global(qos: .userInitiated).async {
            _=AVSpeechSynthesisVoice.speechVoices()
            _=SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
            _=SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
        }
    }
    
    
    
    private func setAudioSession(isRecording: Bool){
        let session = AVAudioSession.sharedInstance()
        do{
            if isRecording {
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            } else {
                try session.setCategory(.playback, mode: .default)
            }
            try session.setActive(true)
        } catch {
            print("fail to set audio session: \(error)")
        }
    }
    
    func startRecording() {
        DispatchQueue.global(qos: .userInitiated).async(){
            self.setAudioSession(isRecording: true)
            
            DispatchQueue.main.async{
                self.myData.removeAll()
            }
            
            let inputNode = self.audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            
            if let url = self.recordingURL {
                self.audioFile = try? AVAudioFile(forWriting: url, settings: format.settings)
            }
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { (buffer, when) in
                self.analyze(buffer: buffer)
                try? self.audioFile?.write(from: buffer)
            }
            
            self.audioEngine.prepare()
            try? self.audioEngine.start()
        }
        
        DispatchQueue.main.async{
            self.isRecording = true
        }
        
        
    }
    
    func playRecording(){
        guard let url = recordingURL else {return}
        DispatchQueue.global(qos: .userInitiated).async{
            do {
                self.setAudioSession(isRecording: false)
                self.audioPlayer?.stop()
                self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                self.audioPlayer?.delegate = self
                self.audioPlayer?.volume = 1.0
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
                
                DispatchQueue.main.async{self.isPlayingRecorded = true}
            } catch {
                print("fail to play audio: \(error)")
            }
        }
        
    }
    
    func playReference(text: String, language: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.setAudioSession(isRecording: false)
            if self.synthesizer.isSpeaking {
                self.synthesizer.stopSpeaking(at: .immediate)
            }
            let utterance = AVSpeechUtterance(string: text)
            let voices = AVSpeechSynthesisVoice.speechVoices().filter{$0.language == language}
            if let premiumVoice = voices.first(where: {$0.quality == .premium}) {
                utterance.voice = premiumVoice
            } else if let enhancedVoice = voices.first(where: { $0.quality == .enhanced }) {
                utterance.voice = enhancedVoice
            } else {
                utterance.voice = AVSpeechSynthesisVoice(language: language)
            }
            print("selected voice is \(utterance.voice?.name ?? "unknown") quality: \(utterance.voice?.quality.rawValue ?? 0)")
            utterance.rate = 0.4
            
            self.synthesizer.delegate = self
            self.synthesizer.speak(utterance)
            DispatchQueue.main.async {self.isPlayingReference = true}
        }
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
    
    private func analyze(buffer: AVAudioPCMBuffer) {
        guard let sample = extractPitch(from: buffer) else { return }
        
        DispatchQueue.main.async {
            if sample.magnitude > 1.5 {
                self.myData.append(sample)
                if self.myData.count > 50 { self.myData.removeFirst() }
            }
        }
    }
    
    //MARK: audio analysis
    private func extractPitch(from buffer: AVAudioPCMBuffer) -> AudioSample? {
        guard let channelData = buffer.floatChannelData?[0] else { return nil }
        let length = Int(buffer.frameLength)
        guard length>0 else { return nil }
        
        var rms: Float = 0.0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(length))
        

        var zeroCrossings = 0
        for i in 1..<length {
            if (channelData[i-1] > 0 && channelData[i] <= 0) || (channelData[i-1] <= 0 && channelData[i] > 0) {
                zeroCrossings += 1
            }
        }
        
        let frequency = Double(zeroCrossings) / (Double(length) / Double(buffer.format.sampleRate)) / 2.0
        return AudioSample(magnitude: rms*50, frequency: frequency)
        
    }
    
    func createReference(text: String, language: String = "en-US", quality: String = "premium") {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.synthesizer.isSpeaking {
                self.synthesizer.stopSpeaking(at: .immediate)
            }
            
            DispatchQueue.main.async{
                self.targetData.removeAll()
            }
            
            let utterance = AVSpeechUtterance(string: text)
            let cacheKey = "\(language)-\(quality)"
            if let cachedVoice = self.voices[cacheKey] {
                utterance.voice = cachedVoice
            } else {
                let voices = AVSpeechSynthesisVoice.speechVoices().filter{$0.language == language}
                if let premiumVoice = voices.first(where: {$0.quality == .premium}) {
                    utterance.voice = premiumVoice
                } else if let enhancedVoice = voices.first(where: { $0.quality == .enhanced }) {
                    utterance.voice = enhancedVoice
                } else {
                    utterance.voice = AVSpeechSynthesisVoice(language: language)
                }
                self.voices[cacheKey]=utterance.voice
            }
            
            utterance.rate = 0.4
            
            self.synthesizer.write(utterance) { buffer in
                guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {return}
                if let sample = self.extractPitch(from: pcmBuffer){
                    DispatchQueue.main.async{
                        self.targetData.append(sample)
                    }
                }
            }
        }
    }
    
    //MARK: intonation scoring
    func pearsonScore(completion: @escaping (Double) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async() {
            let targetFreqs = self.targetData.map { $0.frequency }
            let myFreqs = self.myData.map { $0.frequency }
            let normTarget = self.normalize(targetFreqs)
            let normMy = self.normalize(myFreqs)
            
            guard targetFreqs.count>1, myFreqs.count>1 else {
                DispatchQueue.main.async {
                    completion(0.0)
                }
                return
            }
            
            let resampledTarget = self.resample(normTarget, to:100)
            let resampledMy = self.resample(normMy, to:100)
            
            let correlation = self.pearsonCorrelation(x: resampledTarget, y: resampledMy)
            var intonationScore = 0.0
            if correlation>0 {
                intonationScore = correlation*100
            } else {
                intonationScore = 0
            }
            
            DispatchQueue.main.async {
                completion(intonationScore)
            }
        }
        
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
            
            result.append(data[lowerIndex]*(1-weight)+data[upperIndex]*weight)
        }
        return result
    }
    
    private func pearsonCorrelation(x: [Double], y: [Double]) -> Double {
        guard x.count == y.count, x.count>0 else { return 0.0 }
        
        let n = Double(x.count)
        let meanX = x.reduce(0, +)/n
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
    
    //MARK: pronunciation scoring
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
        let recognizer: SFSpeechRecognizer
        if let catchedRecognizer = recognizers[localeIdentifier] {
            recognizer = catchedRecognizer
        } else {
            guard let newRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)) else {
                
                completion(0.0)
                return
            }
            recognizers[localeIdentifier] = newRecognizer
            recognizer = newRecognizer
        }
        
        guard recognizer.isAvailable else {
            print("not availble to speech regonize (language: \(localeIdentifier))")
            completion(0.0)
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        recognizer.recognitionTask(with: request) { result, error in
            if let error = error {
                print("STT error: \(error.localizedDescription)")
                completion(0.0)
                return
            }
            guard let result = result else {return}
            
            if result.isFinal {
                let recognizedText = result.bestTranscription.formattedString
                print("[\(localeIdentifier)] sentence: \(recognizedText)")
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


