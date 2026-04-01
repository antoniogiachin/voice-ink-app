import Foundation

enum OutputMode: String, CaseIterable, Codable {
    case libero = "libero"
    case promptCodex = "prompt-codex"

    var displayName: String {
        switch self {
        case .libero: return "Libero"
        case .promptCodex: return "Prompt Codex"
        }
    }
}

struct TextProcessor {

    // MARK: - Public API

    /// Processa il testo trascritto in base alla modalità selezionata.
    static func process(_ text: String, mode: OutputMode) -> String {
        guard !text.isEmpty else { return text }

        // 1. Estrai e proteggi token tecnici
        let (sanitized, tokens) = extractTechnicalTokens(text)

        // 2. Applica processing in base alla modalità
        var result: String
        switch mode {
        case .libero:
            result = processLibero(sanitized)
        case .promptCodex:
            result = processPromptCodex(sanitized)
        }

        // 3. Reinserisci token tecnici
        result = restoreTechnicalTokens(result, tokens: tokens)

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Modalità Libero

    /// Corregge punteggiatura, maiuscole e refusi evidenti.
    static func processLibero(_ text: String) -> String {
        var result = text

        // Rimuovi ripetizioni consecutive di parole
        result = removeConsecutiveDuplicates(result)

        // Fix spazi prima della punteggiatura
        result = fixPunctuationSpacing(result)

        // Capitalizza inizio frase
        result = capitalizeSentences(result)

        return result
    }

    // MARK: - Modalità Prompt Codex

    /// Come libero + rimuove filler, unisce frasi frammentate,
    /// rende il testo più operativo.
    static func processPromptCodex(_ text: String) -> String {
        var result = text

        // Rimuovi filler italiani
        result = removeFillerWords(result)

        // Rimuovi ripetizioni consecutive
        result = removeConsecutiveDuplicates(result)

        // Fix spazi multipli (dopo rimozione filler)
        result = result.replacingOccurrences(
            of: "\\s{2,}", with: " ",
            options: .regularExpression
        )

        // Fix punteggiatura
        result = fixPunctuationSpacing(result)

        // Capitalizza
        result = capitalizeSentences(result)

        return result
    }

    // MARK: - Token tecnici

    /// Pattern per identificare token tecnici da preservare.
    private static let technicalPatterns: [(String, NSRegularExpression.Options)] = {
        let patterns: [(String, NSRegularExpression.Options)] = [
            // Testo tra backtick
            ("`[^`]+`", []),
            // Path Unix (assoluti e relativi con /)
            ("(?:~?/[\\w.\\-/]+)", []),
            // URL
            ("https?://[^\\s]+", []),
            // Nomi file con estensione
            ("\\b[\\w\\-]+\\.[a-zA-Z]{1,10}\\b", []),
            // camelCase e PascalCase
            ("\\b[a-z]+(?:[A-Z][a-z]+)+\\b", []),
            ("\\b(?:[A-Z][a-z]+){2,}\\b", []),
            // snake_case
            ("\\b[a-z]+(?:_[a-z]+)+\\b", []),
            // SCREAMING_SNAKE_CASE
            ("\\b[A-Z]+(?:_[A-Z]+)+\\b", []),
            // kebab-case (almeno 2 segmenti con lettere)
            ("\\b[a-z]+(?:-[a-z]+){1,}\\b", []),
            // Stack trace pattern (es. "at Module.func (file:line)")
            ("at\\s+[\\w.]+\\s*\\([^)]+\\)", []),
        ]
        return patterns
    }()

    /// Estrae token tecnici dal testo e li sostituisce con placeholder.
    static func extractTechnicalTokens(_ text: String) -> (String, [(String, String)]) {
        var result = text
        var tokens: [(String, String)] = []
        var counter = 0

        for (pattern, options) in technicalPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
                continue
            }
            let nsRange = NSRange(result.startIndex..., in: result)
            let matches = regex.matches(in: result, options: [], range: nsRange)

            // Processa i match in ordine inverso per non invalidare gli indici
            for match in matches.reversed() {
                guard let range = Range(match.range, in: result) else { continue }
                let token = String(result[range])
                let placeholder = "⟨TK\(counter)⟩"
                tokens.append((placeholder, token))
                result.replaceSubrange(range, with: placeholder)
                counter += 1
            }
        }

        return (result, tokens)
    }

    /// Reinserisce i token tecnici al posto dei placeholder.
    static func restoreTechnicalTokens(_ text: String, tokens: [(String, String)]) -> String {
        var result = text
        for (placeholder, token) in tokens {
            result = result.replacingOccurrences(of: placeholder, with: token)
        }
        return result
    }

    // MARK: - Utility di processing

    /// Filler words italiani comuni nel parlato.
    static let fillerWords: Set<String> = [
        "ehm", "ehm,", "em", "uhm", "ah", "oh",
        "tipo", "cioè", "praticamente", "diciamo",
        "insomma", "allora", "ecco", "niente",
        "fondamentalmente", "sostanzialmente",
        "in pratica", "come dire",
    ]

    /// Rimuove filler words dal testo.
    static func removeFillerWords(_ text: String) -> String {
        // Pattern per filler multi-parola
        var result = text
        let multiWordFillers = ["in pratica", "come dire"]
        for filler in multiWordFillers {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: filler))\\b[,]?\\s*"
            result = result.replacingOccurrences(
                of: pattern, with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }

        // Pattern per filler singola parola
        let singleFillers = fillerWords.filter { !$0.contains(" ") }
        let words = result.components(separatedBy: " ")
        let filtered = words.filter { word in
            let clean = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
            return !singleFillers.contains(clean)
        }
        return filtered.joined(separator: " ")
    }

    /// Rimuove ripetizioni consecutive della stessa parola.
    static func removeConsecutiveDuplicates(_ text: String) -> String {
        text.replacingOccurrences(
            of: "\\b(\\w+)(?:\\s+\\1)+\\b",
            with: "$1",
            options: .regularExpression
        )
    }

    /// Corregge spazi errati attorno alla punteggiatura.
    static func fixPunctuationSpacing(_ text: String) -> String {
        var result = text

        // Rimuovi spazio prima di punteggiatura
        result = result.replacingOccurrences(
            of: "\\s+([.,!?;:])", with: "$1",
            options: .regularExpression
        )

        // Aggiungi spazio dopo punteggiatura se mancante (ma non per abbreviazioni tipo "file.txt")
        result = result.replacingOccurrences(
            of: "([.,!?;:])([A-Za-zÀ-ú])", with: "$1 $2",
            options: .regularExpression
        )

        return result
    }

    /// Capitalizza la prima lettera di ogni frase.
    static func capitalizeSentences(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        var result = ""
        var capitalizeNext = true

        for char in text {
            if capitalizeNext && char.isLetter {
                result.append(char.uppercased())
                capitalizeNext = false
            } else {
                result.append(char)
                if char == "." || char == "!" || char == "?" {
                    capitalizeNext = true
                }
            }
        }

        return result
    }
}
