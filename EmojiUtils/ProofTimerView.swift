//
//  ProofTimerView.swift
//  EmojiUtils
//
//  Created by nichokas on 24/12/24.
//

import SwiftUI

struct ProofTimerView: View {
    let hexSequence: String // Cambiamos el tipo para recibir el hex
    @State private var timeRemaining: Double = 300 // 5 minutes in seconds
    @State private var timer: Timer?
    @State private var showCopiedFeedback = false
    @Environment(\.presentationMode) var presentationMode
    
    // Convertimos el hex a emojis usando la lógica existente
    private var emojiSequence: String {
        let emojiList = HashmojiHelper.getEmojiList()
        let hexData = Data(hexString: hexSequence) ?? Data()
        return HashmojiHelper.hashToEmojis(hashData: hexData, emojiList: emojiList, count: hexSequence.count / 2)
    }
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(lineWidth: 20)
                    .opacity(0.3)
                    .foregroundColor(.gray)
                
                Circle()
                    .trim(from: 0, to: timeRemaining / 300)
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: timeRemaining)
                
                VStack {
                    Text(emojiSequence)
                        .font(.system(size: 40))
                        .onLongPressGesture {
                            UIPasteboard.general.string = emojiSequence
                            // Retroalimentación háptica
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            
                            // Mostrar feedback visual
                            withAnimation {
                                showCopiedFeedback = true
                            }
                            
                            // Ocultar el feedback después de 2 segundos
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showCopiedFeedback = false
                                }
                            }
                        }
                    
                    Text("\(Int(timeRemaining)) seconds")
                        .font(.caption)
                }
            }
            .frame(width: 200, height: 200)
            .overlay(
                // Overlay para el feedback de copiado
                Group {
                    if showCopiedFeedback {
                        Text("¡Copiado!")
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.75))
                            )
                            .transition(.scale.combined(with: .opacity))
                            .zIndex(1)
                    }
                }
            )
            
            Text("Mantén pulsado para copiar")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top)
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// Extensión helper para convertir String hex a Data
extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var i = hexString.startIndex
        for _ in 0..<len {
            let j = hexString.index(i, offsetBy: 2)
            let bytes = hexString[i..<j]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            i = j
        }
        self = data
    }
}
