//
//  InfoView.swift
//  LearningSound
//
//  Created by 윤지희 on 2/20/26.
//

import SwiftUI
struct ScoreInfoView: View{
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 30){
                    Text("How this App calculate your score?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    InfoRow(icon: "waveform.path.ecg",
                            title: "1. Pitch Tracking",
                            description: "We extract the 'pitch' (frequency) of your voice, ignoring volume or background noise.")
                    
                    InfoRow(icon: "arrow.up.and.down.text.horizontal",
                            title: "2. Voice Normalization",
                            description: "Everyone has a different natural voice pitch (e.g., male vs. female). We normalize the data to focus entirely on the 'shape' and 'flow' of your intonation, regardless of how high or low your baseline voice is.")
                    
                    InfoRow(icon: "clock.arrow.2.circlepath",
                            title: "3. Time Alignment",
                            description: "People speak at different speeds. We mathematically align your voice graph to perfectly match the native speaker's timing.")
                    
                    InfoRow(icon: "percent",
                            title: "4. Intonation Match",
                            description: "Finally, we overlap the two graphs. The closer your intonation's shape and rhythm match the native speaker's, the higher your score!")
                }
                .padding(25)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing){
                    Button {
                        dismiss()
                    } label : {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title3)
                    }
                }
            }
        }
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
                            title: "Resonate with speakers in the world",
                            description: "Mastering intonation is the key to speaking naturally. Resonate helps you internalize the rhythm and melody of native speakers through intuitive visual feedback.")
                    InfoRow(icon: "text.cursor",
                            title: "1. select a sentence",
                            description: "select sentence at home view or input the sentence that you like")
                                        
                    InfoRow(icon: "ear",
                            title: "2. learn native's speaker intonation",
                            description: "listen what rhythm do native speakers speak in during watching flow of graph!")
                    
                                        
                    InfoRow(icon: "mic.fill",
                            title: "3. repeat (until you get a satisfying score)",
                            description: "press the mic button and repeat the sentence as shown in the graph.")
                    
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
