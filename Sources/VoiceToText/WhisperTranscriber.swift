import Foundation
import whisper

actor WhisperTranscriber {
    private var context: OpaquePointer?

    private(set) var loadedModelName: String?

    var isModelLoaded: Bool {
        context != nil
    }

    func loadModel(fileName: String = "ggml-base.bin") throws {
        // If the same model is already loaded, skip
        if context != nil && loadedModelName == fileName { return }

        // Unload previous model if switching
        cleanup()

        let path = "\(AudioConstants.modelsDirectory)/\(fileName)"
        guard FileManager.default.fileExists(atPath: path) else {
            throw TranscriberError.modelNotFound(path)
        }

        var params = whisper_context_default_params()
        params.use_gpu = true
        params.flash_attn = true

        guard let ctx = whisper_init_from_file_with_params(path, params) else {
            throw TranscriberError.failedToLoadModel
        }

        context = ctx
        loadedModelName = fileName
    }

    func transcribe(audioData: [Float], language: String = "auto", translate: Bool = false, initialPrompt: String = "") throws -> String {
        guard let ctx = context else {
            throw TranscriberError.modelNotLoaded
        }

        var params = makeBaseParams(translate: translate)
        params.single_segment = false

        let langCString = strdup(language)
        defer { free(langCString) }
        params.language = UnsafePointer(langCString)

        let promptCString = initialPrompt.isEmpty ? nil : strdup(initialPrompt)
        defer { free(promptCString) }
        params.initial_prompt = UnsafePointer(promptCString)

        let result = audioData.withUnsafeBufferPointer { buf in
            whisper_full(ctx, params, buf.baseAddress, Int32(buf.count))
        }

        guard result == 0 else {
            throw TranscriberError.transcriptionFailed
        }

        return Self.cleanTranscription(extractText(from: ctx))
    }

    /// Live-mode transcription: uses single_segment, accepts prompt tokens from the
    /// previous chunk for context continuity, and returns the new prompt tokens
    /// for the next iteration (matching whisper.cpp stream.cpp approach).
    func transcribeLive(
        audioData: [Float],
        language: String = "auto",
        translate: Bool = false,
        promptTokens: [whisper_token] = [],
        initialPrompt: String = ""
    ) throws -> (text: String, tokens: [whisper_token]) {
        guard let ctx = context else {
            throw TranscriberError.modelNotLoaded
        }

        var params = makeBaseParams(translate: translate)
        params.single_segment = true

        let langCString = strdup(language)
        defer { free(langCString) }
        params.language = UnsafePointer(langCString)

        // Only use initial_prompt when there are no prompt tokens (first chunk).
        // After that, prompt_tokens carry context forward.
        let promptCString = (initialPrompt.isEmpty || !promptTokens.isEmpty) ? nil : strdup(initialPrompt)
        defer { free(promptCString) }
        params.initial_prompt = UnsafePointer(promptCString)

        // Feed previous tokens as prompt for context continuity.
        // Both pointers must be valid during whisper_full, so nest the closures.
        let result = promptTokens.withUnsafeBufferPointer { promptBuf in
            params.prompt_tokens = promptBuf.baseAddress
            params.prompt_n_tokens = Int32(promptBuf.count)

            return audioData.withUnsafeBufferPointer { audioBuf in
                whisper_full(ctx, params, audioBuf.baseAddress, Int32(audioBuf.count))
            }
        }

        guard result == 0 else {
            throw TranscriberError.transcriptionFailed
        }

        let segmentCount = whisper_full_n_segments(ctx)
        var text = ""
        var newTokens: [whisper_token] = []

        for i in 0..<segmentCount {
            if let segmentText = whisper_full_get_segment_text(ctx, i) {
                text += String(cString: segmentText)
            }
            let tokenCount = whisper_full_n_tokens(ctx, i)
            for j in 0..<tokenCount {
                newTokens.append(whisper_full_get_token_id(ctx, i, j))
            }
        }

        return (Self.cleanTranscription(text), newTokens)
    }

    // MARK: - Private helpers

    private func makeBaseParams(translate: Bool) -> whisper_full_params {
        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
        params.print_realtime = false
        params.print_progress = false
        params.print_timestamps = false
        params.translate = translate
        params.no_context = true
        params.n_threads = Int32(max(1, ProcessInfo.processInfo.activeProcessorCount / 2))
        return params
    }

    private func extractText(from ctx: OpaquePointer) -> String {
        let segmentCount = whisper_full_n_segments(ctx)
        var text = ""
        for i in 0..<segmentCount {
            if let segmentText = whisper_full_get_segment_text(ctx, i) {
                text += String(cString: segmentText)
            }
        }
        return text
    }

    /// Remove whisper hallucination artifacts: bracketed/parenthesized tags
    /// like [SILENCIO], (music), [BLANK_AUDIO], etc.
    private static func cleanTranscription(_ raw: String) -> String {
        var text = raw
        // Remove [...] and (...) hallucination tags
        text = text.replacingOccurrences(
            of: #"\[.*?\]"#, with: "", options: .regularExpression)
        text = text.replacingOccurrences(
            of: #"\(.*?\)"#, with: "", options: .regularExpression)
        // Collapse extra whitespace
        text = text.replacingOccurrences(
            of: #"\s{2,}"#, with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func cleanup() {
        if let ctx = context {
            whisper_free(ctx)
            context = nil
        }
    }

    deinit {
        if let ctx = context {
            whisper_free(ctx)
        }
    }
}

enum TranscriberError: LocalizedError {
    case modelNotFound(String)
    case failedToLoadModel
    case modelNotLoaded
    case transcriptionFailed

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let path):
            return "Whisper model not found at \(path). Download it first."
        case .failedToLoadModel:
            return "Failed to initialize whisper model."
        case .modelNotLoaded:
            return "Model not loaded. Call loadModel() first."
        case .transcriptionFailed:
            return "Transcription failed."
        }
    }
}
