//
//  HomeView.swift
//  Resonate
//
//  Created by 윤지희 on 2/20/26.
//
import SwiftUI

struct HomeView: View {
    @State private var customText: String = ""
    @State private var customLanguage: String = "en-US"
    @State private var showAppInfoSheet = false
    
    let languages = [
        ("🇺🇸 English", "en-US"),
        ("🇨🇳 Chinese", "zh-CN"),
        ("🇰🇷 Korean", "ko-KR")
    ]
    
    let recommendedSentences = [
        ("I'm looking forward to it!", "en-US", "🇺🇸"),
        ("같이 밥 먹을래?", "ko-KR", "🇰🇷")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 30){
                    VStack(alignment: .leading, spacing: 15){
                        Text("Today's recommended sentences")
                            .font(.title2)
                            .fontWeight(.bold)
                        ForEach(recommendedSentences, id: \.0){ item in
                            NavigationLink(destination: ContentView(practiceText: item.0, selectedLanguage: item.1)) {
                                HStack {
                                    Text(item.2)
                                        .font(.title)
                                    Text(item.0)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(15)
                            }
                        }
                    }
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 15){
                        Text("practice my own sentence")
                            .font(.title2)
                            .fontWeight(.bold)
                        Picker("Language", selection: $customLanguage){
                            ForEach(languages, id:\.1) {lang in
                                Text(lang.0).tag(lang.1)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        HStack {
                            TextField("input the sentence to practice", text: $customText)
                                .textFieldStyle(.roundedBorder)
                            NavigationLink(destination: ContentView(practiceText: customText, selectedLanguage: customLanguage)){
                                Text("Start")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(customText.isEmpty ? Color.gray : Color.blue)
                                    .cornerRadius(8)
                            }
                            .disabled(customText.isEmpty)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Resonate")
        }
    }
}
