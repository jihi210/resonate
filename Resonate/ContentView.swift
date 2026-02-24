//
//  ContentView.swift
//  LearningSound
//
//  Created by 윤지희 on 1/18/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var speechManager = SpeechManager()
    @State private var showNoAlert = false
    @State private var showInfo = false
    
    @State private var myScore : Int = 0
    @State private var intonationScore : Double = 0.0
    @State private var sttScore : Double = 0.0
    
    var practiceText: String
    var selectedLanguage: String
    
    
    var body: some View {
        VStack(spacing: 20) {    
            HStack(alignment: .center, spacing: 15) {
                Text(practiceText)
                    .font(.title2)
                    .multilineTextAlignment(.leading) // 문장이 길면 왼쪽 정렬
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: {
                    speechManager.playReference(text: practiceText, language: selectedLanguage)
                }) {
                    Image(systemName: "speaker.wave.2.circle.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundColor((speechManager.isRecording || speechManager.isPlayingRecorded) ? .blue.opacity(0.5) : .blue)
                }
                .disabled(speechManager.isRecording || speechManager.isPlayingRecorded)
            }
            .padding(.horizontal)
            .padding(.top, 25)
            
            // 그래프 영역
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.05))
                if !speechManager.targetData.isEmpty {
                    PitchLineShape(samples: smoothData(speechManager.targetData))
                        .stroke(Color.gray.opacity(0.4), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                        .padding(20)
                }
                
                if !speechManager.myData.isEmpty {
                    PitchLineShape(samples: speechManager.myData)
                        .stroke(
                            LinearGradient(colors: [.blue, .purple, .pink], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                        )
                        .padding(20)
                        .shadow(color: .purple.opacity(0.3), radius: 5)
                }
            }
            .frame(height: 250)
            .clipped()
            .padding(.horizontal, 20)
            
            // 변환된 텍스트
            VStack(spacing: 10) {
                if myScore == 0{
                    Text("Tap the mic to start speaking...")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                } else {
                    HStack(alignment: .top){
                        Text("\(myScore) points /100")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showInfo = true
                        }) {
                            Image(systemName: "info.circle")
                                .font(.title3)
                                .foregroundColor(.gray)
                        }
                    }
                    Text("meaning: \(Int(sttScore)), intonation: \(Int(intonationScore))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(getFeedbackMessage(intonationScore: intonationScore, sttScore: sttScore))
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .cornerRadius(15)
            .padding(.horizontal, 20)
            
            Spacer()
            
            HStack(spacing: 50){
                Button(action: {
                    if speechManager.isRecording {
                        speechManager.stopRecording()
                        speechManager.pearsonScore() { pearsonScore in
                            DispatchQueue.main.async {
                                self.intonationScore = pearsonScore
                            }
                            if let audioURL = speechManager.recordingURL {
                                speechManager.sttScore(audioURL: audioURL, targetText: practiceText, languageCode: selectedLanguage) { sttScore in
                                    DispatchQueue.main.async {
                                        self.sttScore = sttScore
                                        self.myScore = Int((pearsonScore*0.7)+(sttScore*0.3))
                                        print("\(self.myScore)/100점! (억양: \(Int(pearsonScore)), 발음: \(Int(sttScore)))")
                                    }
                                }
                            }
                        }
        
                    } else {
                        speechManager.startRecording()
                        myScore = 0
                    }
                }) {
                    Image(systemName: speechManager.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .padding(20)
                        .background((speechManager.isPlayingRecorded || speechManager.isPlayingReference) ? Color.gray : (speechManager.isRecording ? Color.red : Color.blue))
                        .clipShape(Circle())
                }
                .disabled(speechManager.isPlayingRecorded || speechManager.isPlayingReference)
                
                Button(action: {
                    if speechManager.myData.isEmpty {
                        showNoAlert = true
                    } else {
                        speechManager.playRecording()
                    }
                }) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 35))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background((speechManager.isRecording || speechManager.isPlayingReference) ? Color.blue.opacity(0.5) : Color.blue)
                        .clipShape(Circle())
                }
                .disabled(speechManager.isRecording || speechManager.isPlayingReference)
            }
        }
        .onAppear {
            speechManager.createReference(text: practiceText, language: selectedLanguage)
        }
        .alert("There is no recorded voice!", isPresented: $showNoAlert) {
            Button("OK", role: .cancel){}
        } message: {
            Text("Please record your voice first by tapping the mic button.")
        }
        .sheet(isPresented: $showInfo){
            ScoreInfoView()
        }
    }
    
    // 주파수(Hz)를 색상으로 바꿔주는 함수
    func getColor(for frequency: Float) -> LinearGradient {
        // 사람 목소리는 보통 85Hz(남자 저음) ~ 255Hz(여자 고음) 사이
        // 400Hz 넘어가면 매우 높은 소리
        
        if frequency < 150 {
            return LinearGradient(colors: [.blue, .purple], startPoint: .bottom, endPoint: .top) // 저음
        } else if frequency < 300 {
            return LinearGradient(colors: [.green, .yellow], startPoint: .bottom, endPoint: .top) // 중음
        } else {
            return LinearGradient(colors: [.orange, .red], startPoint: .bottom, endPoint: .top) // 고음
        }
    }
    
}

struct PitchLineShape: Shape {
    var samples: [AudioSample]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard samples.count>1 else {return path}
        
        let frequencies = samples.map {$0.frequency}
        let minFreq = frequencies.min() ?? 0
        let maxFreq = frequencies.max() ?? 1
        let range = maxFreq - minFreq
        
        for (index, sample) in samples.enumerated() {
            let x = rect.width*CGFloat(index) / CGFloat(samples.count - 1)
            // 상대적 높이 계산 (0.0 ~ 1.0)
            let relativePitch = (sample.frequency - minFreq) / (range > 0 ? range : 1)
                        
            // Y좌표 변환 (높을수록 위로 가야 하므로 1 - relative)
            let y = rect.height * (1 - CGFloat(relativePitch))
                        
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}

func smoothData(_ samples: [AudioSample]) -> [AudioSample] {
    guard samples.count > 2 else {return samples}
    var smoothedSamples = samples
    for i in 1..<samples.count-1{
        let prev = samples[i-1].frequency
        let curr = samples[i].frequency
        let next = samples[i+1].frequency
        let averagedFrequency = (prev*0.2)+(curr*0.6)+(next*0.2)
        smoothedSamples[i] = AudioSample(magnitude: samples[i].magnitude, frequency: averagedFrequency)
    }
    return smoothedSamples
}

func getFeedbackMessage(intonationScore: Double, sttScore: Double) -> String {
    if intonationScore==0 && sttScore==0 {
        return "Tap the mic to start speaking..."
    } else if intonationScore>=80 && sttScore>=90 {
        return "Perfect match! \nBoth your rhythm and pronunciation are flawless!"
    } else if intonationScore>=65 && sttScore<50 {
        return "Great melody! \nYour intonation is spot on, but check your pronunciation."
    } else if intonationScore<40 && sttScore>=80 {
        return "Clear pronunciation! \nThe words are correct, but try to ride the rhythm of the graph."
    } else if intonationScore>=40 && sttScore>=50 {
        return "Good effort! \nYou're getting there. Listen to the reference and try one more time."
    } else {
        return "Let's try again! \nFocus on both the words and the shape of the graph."
    }
}
