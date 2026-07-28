import SwiftUI
import Speech
import AVFoundation

struct VoiceResult {
    var amount: Double = 0
    var category: String = ""
    var note: String = ""
    var isExpense: Bool = true
}

struct VoiceEntryView: View {
    let onResult: (VoiceResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isListening  = false
    @State private var transcript   = ""
    @State private var status       = "Tap the mic to start"
    @State private var result       = VoiceResult()
    @State private var parsed       = false

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-IN"))
    @State private var audioEngine  = AVAudioEngine()
    @State private var request: SFSpeechAudioBufferRecognitionRequest?
    @State private var task: SFSpeechRecognitionTask?

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                // Mic button
                Button(action: toggleListening) {
                    ZStack {
                        Circle()
                            .fill(isListening ? AppTheme.expenseRed.opacity(0.15) : AppTheme.violet.opacity(0.12))
                            .frame(width: 120, height: 120)
                        Circle()
                            .fill(isListening ? AppTheme.expenseRed : AppTheme.violet)
                            .frame(width: 84, height: 84)
                            .scaleEffect(isListening ? 1.08 : 1)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isListening)
                        Image(systemName: isListening ? "stop.fill" : "mic.fill")
                            .font(.system(size: 34))
                            .foregroundColor(.white)
                    }
                }

                Text(status)
                    .font(.headline)
                    .foregroundColor(isListening ? AppTheme.expenseRed : .secondary)
                    .multilineTextAlignment(.center)

                if !transcript.isEmpty {
                    Text(""" + transcript + """)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.systemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }

                // Tips
                VStack(alignment: .leading, spacing: 8) {
                    tipRow("💬", "\"Spent 500 on groceries\"")
                    tipRow("💬", "\"Received 25000 salary\"")
                    tipRow("💬", "\"Paid 1200 electricity bill\"")
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)

                if parsed {
                    Button("Use This Entry") { onResult(result) }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.violet)
                }

                Spacer()
            }
            .navigationTitle("Voice Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { stopListening(); dismiss() }
                }
            }
        }
        .onDisappear { stopListening() }
    }

    private func tipRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 8) {
            Text(icon)
            Text(text).font(.caption).foregroundColor(.secondary)
        }
    }

    private func toggleListening() {
        isListening ? stopListening() : startListening()
    }

    private func startListening() {
        SFSpeechRecognizer.requestAuthorization { auth in
            guard auth == .authorized else {
                DispatchQueue.main.async { status = "Microphone permission needed. Enable in Settings." }
                return
            }
            DispatchQueue.main.async { beginRecognition() }
        }
    }

    private func beginRecognition() {
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let req = request, let rec = recognizer else { return }
        req.shouldReportPartialResults = true

        let node = audioEngine.inputNode
        let fmt  = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: fmt) { buf, _ in req.append(buf) }

        try? audioEngine.start()
        isListening = true
        status = "Listening… speak now"

        task = rec.recognitionTask(with: req) { res, err in
            if let t = res?.bestTranscription.formattedString {
                DispatchQueue.main.async {
                    transcript = t
                    result = parse(t)
                    parsed = true
                    status = "Got it! Review below."
                }
            }
            if res?.isFinal == true || err != nil { stopListening() }
        }
    }

    private func stopListening() {
        task?.cancel(); task = nil
        request?.endAudio(); request = nil
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isListening = false
        if status == "Listening… speak now" { status = "Tap the mic to start" }
    }

    private func parse(_ text: String) -> VoiceResult {
        var r = VoiceResult()
        let lower = text.lowercased()

        // Income keywords
        let incomeWords = ["received", "got", "salary", "income", "earned", "freelance", "refund"]
        r.isExpense = !incomeWords.contains { lower.contains($0) }

        // Amount — find first number
        let nums = text.components(separatedBy: .whitespaces).compactMap { Double($0.filter { $0.isNumber || $0 == "." }) }
        r.amount = nums.first ?? 0

        // Category heuristic
        let catMap: [String: String] = [
            "grocer": "Groceries", "vegetable": "Groceries", "sabzi": "Groceries",
            "food": "Food & Drinks", "lunch": "Food & Drinks", "dinner": "Food & Drinks", "chai": "Food & Drinks",
            "petrol": "Transport", "auto": "Transport", "uber": "Transport", "bus": "Transport",
            "bill": "Bills", "electricity": "Bills", "water": "Bills", "recharge": "Bills",
            "salary": "Salary", "rent": "Rent", "medicine": "Health", "doctor": "Health",
            "emi": "EMI / Loan", "loan": "EMI / Loan",
            "shopping": "Shopping", "cloth": "Shopping",
        ]
        for (keyword, cat) in catMap where lower.contains(keyword) {
            r.category = cat
            break
        }
        if r.category.isEmpty { r.category = r.isExpense ? "Other" : "Other" }

        // Note — use original text minus the amount
        r.note = text
        return r
    }
}
