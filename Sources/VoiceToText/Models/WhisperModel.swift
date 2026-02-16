import Foundation
import SwiftUI

enum WhisperModel: String, CaseIterable {
    // Tiny
    case tiny = "tiny"
    case tinyQ5 = "tiny-q5_1"
    case tinyQ8 = "tiny-q8_0"
    // Base
    case base = "base"
    case baseQ5 = "base-q5_1"
    case baseQ8 = "base-q8_0"
    // Small
    case small = "small"
    case smallQ5 = "small-q5_1"
    case smallQ8 = "small-q8_0"
    // Medium
    case medium = "medium"
    case mediumQ5 = "medium-q5_0"
    case mediumQ8 = "medium-q8_0"
    // Large
    case largeV1 = "large-v1"
    case largeV2 = "large-v2"
    case largeV2Q5 = "large-v2-q5_0"
    case largeV2Q8 = "large-v2-q8_0"
    case largeV3 = "large-v3"
    case largeV3Q5 = "large-v3-q5_0"
    // Large v3 Turbo
    case largeV3Turbo = "large-v3-turbo"
    case largeV3TurboQ5 = "large-v3-turbo-q5_0"
    case largeV3TurboQ8 = "large-v3-turbo-q8_0"

    var fileName: String { "ggml-\(rawValue).bin" }

    var downloadURL: URL {
        URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/\(fileName)")!
    }

    /// File sizes from HuggingFace (ggerganov/whisper.cpp, decimal MB/GB).
    var label: String {
        switch self {
        case .tiny:           return "Tiny (~78 MB)"
        case .tinyQ5:         return "Tiny Q5 (~32 MB)"
        case .tinyQ8:         return "Tiny Q8 (~44 MB)"
        case .base:           return "Base (~148 MB)"
        case .baseQ5:         return "Base Q5 (~60 MB)"
        case .baseQ8:         return "Base Q8 (~82 MB)"
        case .small:          return "Small (~488 MB)"
        case .smallQ5:        return "Small Q5 (~190 MB)"
        case .smallQ8:        return "Small Q8 (~264 MB)"
        case .medium:         return "Medium (~1.5 GB)"
        case .mediumQ5:       return "Medium Q5 (~539 MB)"
        case .mediumQ8:       return "Medium Q8 (~823 MB)"
        case .largeV1:        return "Large v1 (~3.1 GB)"
        case .largeV2:        return "Large v2 (~3.1 GB)"
        case .largeV2Q5:      return "Large v2 Q5 (~1.1 GB)"
        case .largeV2Q8:      return "Large v2 Q8 (~1.7 GB)"
        case .largeV3:        return "Large v3 (~3.1 GB)"
        case .largeV3Q5:      return "Large v3 Q5 (~1.1 GB)"
        case .largeV3Turbo:   return "Large v3 Turbo (~1.6 GB)"
        case .largeV3TurboQ5: return "Large v3 Turbo Q5 (~574 MB)"
        case .largeV3TurboQ8: return "Large v3 Turbo Q8 (~874 MB)"
        }
    }

    /// RAM during inference. Full-precision values from whisper.cpp README;
    /// quantized values estimated as: file_size + family_overhead.
    var ramUsage: String {
        switch self {
        case .tiny:           return "~273 MB"
        case .tinyQ5:         return "~230 MB"
        case .tinyQ8:         return "~240 MB"
        case .base:           return "~388 MB"
        case .baseQ5:         return "~300 MB"
        case .baseQ8:         return "~320 MB"
        case .small:          return "~852 MB"
        case .smallQ5:        return "~550 MB"
        case .smallQ8:        return "~630 MB"
        case .medium:         return "~2.1 GB"
        case .mediumQ5:       return "~1.1 GB"
        case .mediumQ8:       return "~1.4 GB"
        case .largeV1:        return "~3.9 GB"
        case .largeV2:        return "~3.9 GB"
        case .largeV2Q5:      return "~1.9 GB"
        case .largeV2Q8:      return "~2.5 GB"
        case .largeV3:        return "~3.9 GB"
        case .largeV3Q5:      return "~1.9 GB"
        case .largeV3Turbo:   return "~2.3 GB"
        case .largeV3TurboQ5: return "~1.2 GB"
        case .largeV3TurboQ8: return "~1.5 GB"
        }
    }

    var quantizationNote: String? {
        switch self {
        case .tinyQ8, .baseQ8, .smallQ8, .mediumQ8,
             .largeV2Q8, .largeV3TurboQ8:
            return "8-bit"
        case .tinyQ5, .baseQ5, .smallQ5, .mediumQ5,
             .largeV2Q5, .largeV3Q5, .largeV3TurboQ5:
            return "5-bit"
        default:
            return nil
        }
    }

    var localPath: String { "\(AudioConstants.modelsDirectory)/\(fileName)" }

    var isDownloaded: Bool {
        FileManager.default.fileExists(atPath: localPath)
    }

    struct ModelChip {
        let text: String
        let style: ChipStyle

        enum ChipStyle {
            /// Green — recommended / best for a use case
            case positive
            /// Blue — neutral-positive info (speed, accuracy tier)
            case info
            /// Orange — caution (slow, low accuracy, outdated)
            case caution

            var color: Color {
                switch self {
                case .positive: return .green
                case .info:     return .blue
                case .caution:  return .orange
                }
            }
        }
    }

    enum Family: String, CaseIterable {
        case tiny = "Tiny"
        case base = "Base"
        case small = "Small"
        case medium = "Medium"
        case large = "Large"

        var models: [WhisperModel] {
            WhisperModel.allCases.filter { $0.family == self }
        }
    }

    var family: Family {
        switch self {
        case .tiny, .tinyQ5, .tinyQ8:                          return .tiny
        case .base, .baseQ5, .baseQ8:                          return .base
        case .small, .smallQ5, .smallQ8:                       return .small
        case .medium, .mediumQ5, .mediumQ8:                    return .medium
        case .largeV1, .largeV2, .largeV2Q5, .largeV2Q8,
             .largeV3, .largeV3Q5,
             .largeV3Turbo, .largeV3TurboQ5, .largeV3TurboQ8: return .large
        }
    }

    private var isTurbo: Bool {
        switch self {
        case .largeV3Turbo, .largeV3TurboQ5, .largeV3TurboQ8: return true
        default: return false
        }
    }

    /// Static chips based on whisper.cpp benchmarks, OpenAI WER data,
    /// and real-time feasibility on Apple Silicon.
    /// Speed relative to Large (1x): Tiny ~10x, Base ~7x, Small ~4x,
    /// Medium ~2x, Turbo ~8x.  WER (mixed): Large-v3 ~7.4%, Turbo ~7.7%,
    /// Small/Medium mid-range, Base/Tiny highest error.
    var chips: [ModelChip] {
        switch self {
        // ── Tiny ────────────────────────────────────
        case .tiny, .tinyQ5, .tinyQ8:
            return [ModelChip(text: "Low accuracy", style: .caution)]

        // ── Base ────────────────────────────────────
        case .base, .baseQ5, .baseQ8:
            return [ModelChip(text: "Best for live", style: .positive)]

        // ── Small ───────────────────────────────────
        case .small, .smallQ5, .smallQ8:
            return [ModelChip(text: "Best balance", style: .positive)]

        // ── Medium ──────────────────────────────────
        case .mediumQ5:
            return [ModelChip(text: "Recommended", style: .positive)]
        case .medium, .mediumQ8:
            return []

        // ── Large v1 ───────────────────────────────
        case .largeV1:
            return [ModelChip(text: "Outdated", style: .caution)]

        // ── Large v2 ───────────────────────────────
        case .largeV2, .largeV2Q5, .largeV2Q8:
            return []

        // ── Large v3 ───────────────────────────────
        case .largeV3, .largeV3Q5:
            return []

        // ── Large v3 Turbo ─────────────────────────
        case .largeV3Turbo, .largeV3TurboQ5, .largeV3TurboQ8:
            return [ModelChip(text: "Best for batch", style: .positive)]
        }
    }
}
