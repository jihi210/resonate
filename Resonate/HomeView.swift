import SwiftUI
import NaturalLanguage

struct HomeView: View {
    @State private var customText: String = ""
    @State private var isTypingCustom: Bool = false
    @State private var showAppInfoSheet = false
    @AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    @State private var navigateToCustom: Bool = false
    
    @FocusState private var isInputFocused: Bool
    @State private var targetText: String = ""
    @State private var targetLang: String = "en-US"
    @State private var recommendedSentences = [
        ("I'm looking forward to it!", "en-US", "🇺🇸"),
        ("같이 밥 먹을래?", "ko-KR", "🇰🇷")
    ]
    @State private var showScoreInfoTest = false
    private let languageRecognizer = NLLanguageRecognizer()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20){
                    Text("Today's sentences")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 10)
                    
                    ForEach(recommendedSentences, id: \.0){ item in
                        NavigationLink(destination: ContentView(practiceText: item.0, selectedLanguage: item.1)) {
                            HStack {
                                Text(item.2)
                                    .font(.title)
                                Text(item.0)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .cornerRadius(15)
                            .contextMenu {
                                if item.0=="I'm looking forward to it!" || item.0=="같이 밥 먹을래?" {
                                    Button(action: {
                                        
                                    }) {
                                        Label("Default Sentence", systemImage: "lock.fill")
                                    }
                                } else {
                                    Button(role: .destructive, action: {
                                        withAnimation {
                                            recommendedSentences.removeAll {$0.0==item.0}
                                        }
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    if isTypingCustom {
                        HStack {
                            TextField("Type a sentence and press Return", text: $customText)
                                .font(.headline)
                                .focused($isInputFocused)
                                .onAppear() { isInputFocused = true }
                                .submitLabel(.done)
                                .onSubmit {
                                    if !customText.isEmpty {
                                        detectLanguage(for: customText) { detectedLang in
                                            let flag = getFlag(for: detectedLang)
                                            
                                            if !recommendedSentences.contains(where: {$0.0==customText}) {
                                                recommendedSentences.append((customText, detectedLang, flag))
                                            }
                                            targetText = customText
                                            targetLang = detectedLang
                                            navigateToCustom = true
                                        }
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now()+0.5){
                                            customText = ""
                                            isTypingCustom = false
                                        }
                     
                                    }
                                }
                                
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
                            .background(Color.white)
                            .cornerRadius(15)
                            
                        }
                    }
                    
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
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
            .onAppear {
                if isFirstLaunch {
                    showAppInfoSheet = true
                    isFirstLaunch = false
                }
            }
            .sheet(isPresented: $showAppInfoSheet) {
                AppInfoView()
            }
            .navigationDestination(isPresented: $navigateToCustom) {
                ContentView(practiceText: targetText, selectedLanguage: targetLang)
            }
        }
    }
    private func detectLanguage(for text: String, completion: @escaping (String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async{
            self.languageRecognizer.reset()
            self.languageRecognizer.processString(text)
            
            let langCode = self.languageRecognizer.dominantLanguage?.rawValue ?? "en-US"
            let resultCode: String
            switch langCode {
                case "ko": resultCode = "ko-KR"
                case "en": resultCode = "en-US"
                case "es": resultCode = "es-ES"
                case "zh", "zh-Hans", "zh-Hant": resultCode = "zh-CN"
                case "ja": resultCode = "ja-JP"
                default: resultCode = "unknown"
            }
            
            DispatchQueue.main.async{
                completion(resultCode)
            }
            
        }
    }
    
    private func getFlag(for languageCode: String)-> String {
        switch languageCode {
            case "ko-KR": return "🇰🇷"
            case "en-US": return "🇺🇸"
            case "es-ES": return "🇪🇸"
            case "zh-CN": return "🇨🇳"
            case "ja-JP": return "🇯🇵"
            default: return "💬"
        }
    }
}
