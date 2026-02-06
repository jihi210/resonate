//
//  ContentView.swift
//  LearningSound
//
//  Created by 윤지희 on 1/18/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var speechManager = SpeechManager()
    @State private var targetSamples: [AudioSample] = []
    
    let practiceText = "Nice to meet you"
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Resonate")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(practiceText)
                .font(.title2)
                .foregroundColor(.gray)
            
            // 그래프 영역
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.05))
                if !targetSamples.isEmpty {
                    PitchLineShape(samples: targetSamples)
                        .stroke(Color.gray.opacity(0.4), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                        .padding(20)
                }
                
                if !speechManager.audioSamples.isEmpty {
                    PitchLineShape(samples: speechManager.audioSamples)
                        .stroke(
                            LinearGradient(colors: [.blue, .purple, .pink], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                        )
                        .padding(20)
                        .shadow(color: .purple.opacity(0.3), radius: 5)
                }
            }
            .frame(height: 250)
            .padding()
            
            // 변환된 텍스트
            ScrollView {
                Text(speechManager.transcript.isEmpty ? "말씀해 보세요..." : speechManager.transcript)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(height: 150)
            
            // 녹음 버튼
            Button(action: {
                if speechManager.isRecording {
                    speechManager.stopRecording()
                } else {
                    speechManager.startRecording()
                }
            }) {
                Image(systemName: speechManager.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .padding(20)
                    .background(speechManager.isRecording ? Color.red : Color.blue)
                    .clipShape(Circle())
            }
            
            Button(action: {
                speechManager.playRecording()
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("내 녹음 듣기")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(speechManager.isRecording)
            .opacity(speechManager.isRecording ? 0.5 : 1.0)
            
        }
        .onAppear {
            speechManager.generateReferenceData(text: practiceText) { samples in
                self.targetSamples = samples
            }
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
