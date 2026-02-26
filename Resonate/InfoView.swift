import SwiftUI
struct ScoreInfoView: View{
    @State private var matchLength = false
    @State private var matchAmplitude = false
    let referenceData: [Double] = [0.2, 0.3, 0.25, 0.6, 0.9, 0.7, 0.4, 0.3, 0.2, 0.3, 0.25, 0.5, 0.8, 0.6, 0.3, 0.2]
    let userData: [Double] = [0.1, 0.2, 0.15, 0.5, 0.95, 0.8, 0.3, 0.2, 0.1, 0.2, 0.15, 0.4, 0.9, 0.7, 0.2, 0.1]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            TabView {
                VStack(spacing: 45) {
                    Text("Step 1")
                        .font(.title3)
                                
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
                        
                        HStack(spacing: 20) {
                            ForEach(0..<4) { index in
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 15, height: 15)
                            }
                        }
                    }
                    .frame(height: 250)
                    
                    Text("Finding the exact pitch using\nZero-Crossing Count!")
                        .multilineTextAlignment(.center)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .tag(0)
                .offset(x:0, y:-30)
                
                VStack(spacing: 45) {
                    Text("Step 2")
                        .font(.title3)
                    
                    
                    Text("Normalize & Resample")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    ZStack {
                        WaveShape(dataPoints: referenceData)
                            .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            .frame(width: 300, height: 150)
                            .drawingGroup()
                        WaveShape(dataPoints: userData)
                            .stroke(
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                            )
                            .scaleEffect(
                                x: matchLength ? 1.0 : 0.7,
                                y: matchAmplitude ? 1.0 : 1.3,
                                anchor: .leading
                            )
                            .frame(width: 300, height: 150)
                            .drawingGroup()
                        
                        HStack(spacing: 0) {
                            Image(systemName: "arrowtriangle.left.fill").font(.system(size: 12))
                            Rectangle().frame(height: 2)
                            Image(systemName: "arrowtriangle.right.fill").font(.system(size: 12))
                        }
                        .foregroundColor(.blue.opacity(0.8))
                        .frame(width: 300)
                        .opacity(matchLength ? 0 : 1)
                        .offset(y: 95)

                        VStack(spacing: 0) {
                            Image(systemName: "arrowtriangle.up.fill").font(.system(size: 12))
                            Rectangle().frame(width: 2)
                            Image(systemName: "arrowtriangle.down.fill").font(.system(size: 12))
                        }
                        .foregroundColor(.purple.opacity(0.8))
                        .frame(height: 150)
                        .opacity((matchLength && !matchAmplitude) ? 1 : 0)
                        .offset(x: 170)
                    }
                    .frame(height: 250)
                    
                    VStack(spacing: 10) {
                        Text("Fitting the range (Amplitude)\n length (Time) to compare!")
                            .multilineTextAlignment(.center)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                }
                .offset(x:0, y:-30)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 1.5)) {
                            matchLength = true
                        }
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeInOut(duration: 1.5)) {
                            matchAmplitude = true
                        }
                    }
                }
                
                VStack(spacing: 45) {
                    Text("Step 3")
                        .font(.title3)
                    
                    
                    Text("Scoring")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    VStack {
                        HStack(spacing: 25) {
                            ZStack {
                                WaveShape(dataPoints: referenceData)
                                    .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                    .drawingGroup()
                                WaveShape(dataPoints: userData)
                                    .stroke(
                                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing),
                                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                                    )
                                    .drawingGroup()
                            }
                            .frame(width: 140, height: 40)
                            
                            VStack(alignment: .trailing) {
                                Text("Intonation (Pearson)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("60 / 70")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .frame(width: 330, height: 90)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    
                        HStack(spacing: 25) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Ref: I am a student")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("You: I am a student")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 140)
                
                            VStack(alignment: .trailing) {
                                Text("Pronunciation (STT)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("30 / 30")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                        }
                        .padding()
                        .frame(width: 330, height: 90)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        
                    }
                    .frame(height: 250)
                        
                    VStack(spacing: 10) {
                        Text("Calculate your final score. \nIt reflects both pronunciation and intonation.")
                            .multilineTextAlignment(.center)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                        
                }
                .offset(x:0, y:-30)
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
    let dataPoints: [Double]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard dataPoints.count > 1 else {return path}
        let width = rect.width
        let height = rect.height
        let stepX = width/CGFloat(dataPoints.count-1)
        
        path.move(to: CGPoint(x: 0, y: height*(1.0-CGFloat(dataPoints[0]))))
        
        for index in 1..<dataPoints.count {
            let x = stepX*CGFloat(index)
            let y = height*(1.0-CGFloat(dataPoints[index]))
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
