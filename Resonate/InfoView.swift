//
//  InfoView.swift
//  LearningSound
//
//  Created by 윤지희 on 2/20/26.
//

import SwiftUI
struct ScoreInfoView: View{
    @State private var isAnimating2 = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            TabView {
                VStack(spacing: 40) {
                    Text("Step 1")
                        .font(.headline)
                        .foregroundColor(.blue)
                                
                    Text("Extract Pitch Data")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                                
                    ZStack {
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(.gray.opacity(0.5))
                    
                        Image(systemName: "waveform.path.ecg")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200)
                            .foregroundColor(.blue)
                        
                        HStack(spacing: 40) {
                            ForEach(0..<4) { index in
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 15, height: 15)
                            }
                        }
                    }
                    .frame(height: 200)
                    
                    Text("Finding the exact pitch using\nZero-Crossing Count!")
                        .multilineTextAlignment(.center)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .tag(0)
                
                VStack(spacing: 40) {
                    Text("Step 2")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("Normalize & Resample")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 30) {
                        WaveShape()
                            .stroke(Color.blue, lineWidth: 3)
                            .frame(width: 250, height: 80)
                        
                        WaveShape()
                            .stroke(Color.red, lineWidth: 3)
                            .frame(width: 250, height: 80)
                            .scaleEffect(
                                x: isAnimating2 ? 1.0 : 0.6,
                                y: isAnimating2 ? 1.0 : 1.5,
                                anchor: .leading
                            )
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                                value: isAnimating2
                            )
                    }
                    .frame(height: 250)
                    
                    Text("Fitting the range (Amplitude)\nand length (Time) to compare!")
                        .multilineTextAlignment(.center)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .onAppear {
                    isAnimating2 = true
                }
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midHeight = rect.height / 2
        let width = rect.width
        let wavelength = width / 3
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / wavelength
            let sine = sin(relativeX * .pi * 2)
            let y = midHeight - (sine * midHeight)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }
}

struct AppInfoView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    Text("Welcome to Resonate")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    InfoRow(icon: "lightbulb.fill",
                            title: "Resonate with speakers around the world",
                            description: "Mastering intonation is the key to speaking naturally. Resonate helps you internalize the rhythm and melody of native speakers through intuitive visual feedback.")
                    InfoRow(icon: "text.cursor",
                            title: "1. Select a sentence",
                            description: "Choose a recommended sentence from the home screen, or type your own.")
                                        
                    InfoRow(icon: "ear",
                            title: "2. Listen to the Rhythm",
                            description: "Listen to the native speaker's rhythm while watching the flow of the graph.")
                    
                                        
                    InfoRow(icon: "mic.fill",
                            title: "3. Practice & Repeat",
                            description: "Tap the mic button and repeat the sentence, trying to match the curve of the graph.")
                    
                    Divider()
                        .padding(.vertical, 10)
                    
                    InfoRow(icon: "person.wave.2.fill",
                            title: "Tip: Choose Your Tutor Voice",
                            description: "Go to your iPhone's \n[Settings > Accessibility > Spoken Content > Voices] \nand download your favorite voice. \nHigher quality voices will be prioritized.")
                }
                .padding(25)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {dismiss()} label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title3)
                    }
                }
            }
        }
    }
}
struct InfoRow: View {
    var icon: String
    var title: String
    var description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.blue)
                .frame(width: 40)
            VStack (alignment: .leading, spacing: 5){
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
