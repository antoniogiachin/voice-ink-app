import XCTest

@testable import VoceInk

final class TextProcessorTests: XCTestCase {

    // MARK: - Capitalizzazione

    func testCapitalizeSentences() {
        XCTAssertEqual(
            TextProcessor.capitalizeSentences("ciao mondo. come stai? bene!"),
            "Ciao mondo. Come stai? Bene!"
        )
    }

    func testCapitalizeEmptyString() {
        XCTAssertEqual(TextProcessor.capitalizeSentences(""), "")
    }

    func testCapitalizeAlreadyCapitalized() {
        XCTAssertEqual(
            TextProcessor.capitalizeSentences("Tutto ok. Niente da fare."),
            "Tutto ok. Niente da fare."
        )
    }

    // MARK: - Punteggiatura

    func testFixPunctuationSpacing() {
        XCTAssertEqual(
            TextProcessor.fixPunctuationSpacing("ciao , mondo . come stai ?"),
            "ciao, mondo. come stai?"
        )
    }

    func testFixPunctuationNoSpaceAfter() {
        XCTAssertEqual(
            TextProcessor.fixPunctuationSpacing("ciao.mondo"),
            "ciao. mondo"
        )
    }

    // MARK: - Ripetizioni consecutive

    func testRemoveConsecutiveDuplicates() {
        XCTAssertEqual(
            TextProcessor.removeConsecutiveDuplicates("il il gatto gatto nero"),
            "il gatto nero"
        )
    }

    func testNoDuplicates() {
        XCTAssertEqual(
            TextProcessor.removeConsecutiveDuplicates("il gatto nero"),
            "il gatto nero"
        )
    }

    // MARK: - Filler words (prompt-codex)

    func testRemoveFillerWords() {
        let input = "ehm voglio tipo creare un file cioè un nuovo file"
        let result = TextProcessor.removeFillerWords(input)
        XCTAssertFalse(result.contains("ehm"))
        XCTAssertFalse(result.contains("tipo"))
        XCTAssertFalse(result.contains("cioè"))
        XCTAssertTrue(result.contains("voglio"))
        XCTAssertTrue(result.contains("creare"))
    }

    func testRemoveMultiWordFillers() {
        let input = "in pratica devo fare una cosa come dire importante"
        let result = TextProcessor.removeFillerWords(input)
        XCTAssertFalse(result.lowercased().contains("in pratica"))
        XCTAssertFalse(result.lowercased().contains("come dire"))
        XCTAssertTrue(result.contains("devo"))
        XCTAssertTrue(result.contains("importante"))
    }

    func testNoFillers() {
        let input = "crea un nuovo file nella cartella sources"
        XCTAssertEqual(
            TextProcessor.removeFillerWords(input),
            input
        )
    }

    // MARK: - Token tecnici

    func testPreservePaths() {
        let input = "apri il file /Users/test/main.swift"
        let result = TextProcessor.process(input, mode: .libero)
        XCTAssertTrue(result.contains("/Users/test/main.swift"))
    }

    func testPreserveTildePath() {
        let input = "vai in ~/Developer/progetto"
        let result = TextProcessor.process(input, mode: .libero)
        XCTAssertTrue(result.contains("~/Developer/progetto"))
    }

    func testPreserveFileNames() {
        let input = "modifica il file package.json e tsconfig.json"
        let result = TextProcessor.process(input, mode: .libero)
        XCTAssertTrue(result.contains("package.json"))
        XCTAssertTrue(result.contains("tsconfig.json"))
    }

    func testPreserveCamelCase() {
        let input = "chiama la funzione getUserName nel modulo"
        let result = TextProcessor.process(input, mode: .libero)
        XCTAssertTrue(result.contains("getUserName"))
    }

    func testPreserveSnakeCase() {
        let input = "usa la variabile user_name nel codice"
        let result = TextProcessor.process(input, mode: .libero)
        XCTAssertTrue(result.contains("user_name"))
    }

    func testPreserveURL() {
        let input = "vai su https://github.com/test/repo"
        let result = TextProcessor.process(input, mode: .libero)
        XCTAssertTrue(result.contains("https://github.com/test/repo"))
    }

    func testPreserveBacktickCode() {
        let input = "esegui il comando `git status` nel terminale"
        let result = TextProcessor.process(input, mode: .libero)
        XCTAssertTrue(result.contains("`git status`"))
    }

    // MARK: - Modalità libero end-to-end

    func testLiberoMode() {
        let input = "ciao mondo . come stai ? bene bene , grazie"
        let result = TextProcessor.process(input, mode: .libero)
        // Deve capitalizzare, fixare punteggiatura, rimuovere duplicati
        XCTAssertTrue(result.hasPrefix("C"))  // Capitalizzata
        XCTAssertFalse(result.contains(" ."))  // No spazio prima del punto
        XCTAssertFalse(result.contains("bene bene"))  // No duplicati
    }

    // MARK: - Modalità prompt-codex end-to-end

    func testPromptCodexMode() {
        let input = "ehm praticamente voglio tipo creare un nuovo file . cioè un componente react"
        let result = TextProcessor.process(input, mode: .promptCodex)
        XCTAssertFalse(result.lowercased().contains("ehm"))
        XCTAssertFalse(result.lowercased().contains("praticamente"))
        XCTAssertFalse(result.lowercased().contains("tipo"))
        XCTAssertFalse(result.lowercased().contains("cioè"))
        XCTAssertTrue(result.lowercased().contains("voglio"))
        XCTAssertTrue(result.lowercased().contains("componente"))
    }

    // MARK: - Edge cases

    func testEmptyString() {
        XCTAssertEqual(TextProcessor.process("", mode: .libero), "")
        XCTAssertEqual(TextProcessor.process("", mode: .promptCodex), "")
    }

    func testOnlyTechnicalTokens() {
        let input = "/usr/bin/swift main.swift ~/Desktop"
        let result = TextProcessor.process(input, mode: .libero)
        XCTAssertTrue(result.contains("/usr/bin/swift"))
        XCTAssertTrue(result.contains("main.swift"))
    }

    func testMixedItalianAndCommands() {
        let input = "esegui git checkout -b feature/nuova-cosa nella repo ~/progetti/app"
        let result = TextProcessor.process(input, mode: .promptCodex)
        XCTAssertTrue(result.contains("~/progetti/app"))
    }
}
