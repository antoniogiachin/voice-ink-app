import XCTest

@testable import VoceInk

final class TranscriberTests: XCTestCase {

    // MARK: - Parse output

    func testParseOutputClean() {
        let raw = "Ciao mondo come stai"
        XCTAssertEqual(Transcriber.parseOutput(raw), "Ciao mondo come stai")
    }

    func testParseOutputMultiline() {
        let raw = """
        Prima riga del testo.
        Seconda riga del testo.
        Terza riga.
        """
        let result = Transcriber.parseOutput(raw)
        XCTAssertEqual(result, "Prima riga del testo. Seconda riga del testo. Terza riga.")
    }

    func testParseOutputWithEmptyLines() {
        let raw = """

        Testo con righe vuote

        in mezzo

        """
        let result = Transcriber.parseOutput(raw)
        XCTAssertEqual(result, "Testo con righe vuote in mezzo")
    }

    func testParseOutputWithWhitespace() {
        let raw = "   testo con spazi   "
        XCTAssertEqual(Transcriber.parseOutput(raw), "testo con spazi")
    }

    func testParseOutputEmpty() {
        XCTAssertEqual(Transcriber.parseOutput(""), "")
        XCTAssertEqual(Transcriber.parseOutput("   \n  \n  "), "")
    }

    func testParseOutputWithTimestampLikeContent() {
        // whisper con --no-timestamps non dovrebbe avere timestamp,
        // ma verifichiamo che il testo normale passi comunque
        let raw = "Questo è un testo normale senza timestamp"
        XCTAssertEqual(
            Transcriber.parseOutput(raw),
            "Questo è un testo normale senza timestamp"
        )
    }
}
