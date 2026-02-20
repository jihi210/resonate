//
//  InfoView.swift
//  LearningSound
//
//  Created by 윤지희 on 2/20/26.
//

import SwiftUI
struct InfoView: View{
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
