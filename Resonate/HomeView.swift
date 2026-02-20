//
//  HomeView.swift
//  Resonate
//
//  Created by 윤지희 on 2/20/26.
//
import SwiftUI
import NaturalLanguage

struct HomeView: View {
    @State private var customText: String = ""
    @State private var isTypingCustom: Bool = false
    @State private var showAppInfoSheet = false
    @State private var navigateToCustom: Bool = false
    
    let recommendedSentences = [
        ("I'm looking forward to it!", "en-US", "🇺🇸"),
        ("같이 밥 먹을래?", "ko-KR", "🇰🇷")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20){
                    Text("Today's sentences")
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
                            .cornerRadius(15)
                        }
                    }
                    if isTypingCustom {
                        HStack {
                            TextField("Type a sentence and press Return", text: $customText)
                                .font(.headline)
                                .onSubmit {
                                    if !customText.isEmpty {
                                        navigateToCustom = true
                                    }
                                }
                            NavigationLink(
                                destination: ContentView(practiceText: customText, selectedLanguage: detectLanguage(for: customText)),
                                isActive: $navigateToCustom
                            ) {EmptyView()}
                                
                            Button(action: {
                                isTypingCustom = false
                                customText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                    } else {
                        Button(action: {
                            withAnimation {isTypingCustom=true}
                        }) {
                            HStack{
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text("Type your own sentence")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding()
                            .background(Color.blue.opacity(0.08))
                            .cornerRadius(15)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
            }
            .navigationTitle("Resonate")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAppInfoSheet = true }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showAppInfoSheet) {
                AppInfoView()
            }
        }
    }
    private func detectLanguage(for text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let langCode = recognizer.dominantLanguage?.rawValue else {return "en-US"}
        
        switch langCode {
        case "ko": return "ko-KR"
        case "en": return "en-US"
        case "es": return "es-ES"
        case "zh", "zh-Hans", "zh-Hant": return "zh-CN"
        case "ja": return "ja-JP"
        default: return "en-US" // 기본값은 영어
        }
    }
}
