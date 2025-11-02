//
//  ContentView.swift
//  TranslateMe
//
//  Created by Sehr Abrar on 11/2/25.
//

import SwiftUI

struct Translation: Identifiable, Codable {
    var id = UUID()
    var original: String
    var translated: String
}

struct ContentView: View {
    @State private var inputText = ""
    @State private var translatedText = ""
    @State private var history: [Translation] = []
    
    // Store the JSON-encoded history in UserDefaults
    @AppStorage("translationHistory") private var storedHistoryData: Data = Data()
    
    init() {
        // Load saved history from UserDefaults when app starts
        if let decoded = try? JSONDecoder().decode([Translation].self, from: storedHistoryData),
           !decoded.isEmpty {
            _history = State(initialValue: decoded)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Enter text to translate", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button("Translate") {
                    Task {
                        await translateText()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Text(translatedText)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                Divider()
                
                Text("Translation History")
                    .font(.headline)
                
                List(history) { item in
                    VStack(alignment: .leading) {
                        Text(item.original).bold()
                        Text(item.translated)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button("Clear History") {
                    history.removeAll()
                    saveHistory() // also clear storage
                }
                .foregroundColor(.red)
                .padding(.bottom)
            }
            .navigationTitle("TranslateMe 🌐")
        }
    }
    
    // MARK: - Translation Function
    func translateText() async {
        guard !inputText.isEmpty else { return }
        
        let encodedText = inputText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.mymemory.translated.net/get?q=\(encodedText)&langpair=en|es"
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let decoded = try? JSONDecoder().decode(MyMemoryResponse.self, from: data) {
                let translation = decoded.responseData.translatedText
                translatedText = translation
                
                let newItem = Translation(original: inputText, translated: translation)
                history.insert(newItem, at: 0)
                saveHistory() // Save updated history to disk
            }
        } catch {
            translatedText = "Error: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Local Persistence
    func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            storedHistoryData = encoded
        }
    }
}

struct MyMemoryResponse: Codable {
    struct ResponseData: Codable {
        let translatedText: String
    }
    let responseData: ResponseData
}
