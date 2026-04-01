# VoceInk

App menu bar per macOS Apple Silicon: registra audio dal microfono, trascrive in italiano con whisper.cpp (100% locale), post-processa il testo e lo inserisce nel campo attivo del terminale.

**Zero cloud. Zero telemetria. Zero upload audio.**

## Requisiti

- macOS 14+ (Sonoma o successivo)
- Apple Silicon (M1/M2/M3/M4)
- Xcode Command Line Tools (`xcode-select --install`)
- Homebrew con `cmake` (`brew install cmake`)
- ~2 GB di spazio disco (whisper.cpp + modello medium)

## Setup

```bash
# 1. Clona whisper.cpp, compila e scarica il modello medium (~1.5 GB)
./scripts/setup.sh

# 2. Compila VoceInk e crea il bundle .app
./scripts/build.sh

# 3. Avvia
open build/VoceInk.app
```

### Permessi richiesti al primo avvio

- **Microfono**: System Settings > Privacy & Security > Microphone > VoceInk
- **Accessibilita**: System Settings > Privacy & Security > Accessibility > VoceInk
  (necessario per il paste automatico nel terminale)

## Utilizzo

1. Avvia VoceInk: appare un'icona microfono nella menu bar
2. Premi **Ctrl + Shift + Space** per iniziare a registrare (icona rossa)
3. Parla in italiano
4. Premi **Ctrl + Shift + Space** di nuovo per fermare e trascrivere
5. Il testo trascritto viene inserito automaticamente nel campo attivo

### Modalita di output

| Modalita | Descrizione |
|----------|-------------|
| **Libero** (default) | Corregge punteggiatura, maiuscole e refusi evidenti. Preserva il contenuto originale. |
| **Prompt Codex** | Come Libero + rimuove filler ("ehm", "tipo", "cioe"), rende il testo piu operativo per prompt di sviluppo. |

Cambia modalita dal menu dropdown nella menu bar o dalle Impostazioni.

### Token tecnici preservati

In entrambe le modalita, VoceInk preserva automaticamente:
- Path Unix (`/usr/bin/swift`, `~/Developer/progetto`)
- URL (`https://github.com/...`)
- Nomi file (`package.json`, `main.swift`)
- Identificatori codice: camelCase, PascalCase, snake_case, SCREAMING_SNAKE_CASE, kebab-case
- Testo tra backtick (\`git status\`)
- Stack trace

## Configurazione

Apri le impostazioni dalla menu bar (o Cmd+,):

- **Modalita output**: Libero / Prompt Codex
- **Modello Whisper**: seleziona tra i modelli .bin disponibili nella cartella `models/`
- **Path whisper-cli**: override del percorso di whisper-cli
- **Hotkey**: default Ctrl+Shift+Space

### Modelli alternativi

Per scaricare modelli diversi:

```bash
# Small (~500 MB, piu veloce ma meno preciso)
curl -L https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin -o models/ggml-small.bin

# Large v3 (~3 GB, massima qualita)
curl -L https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3.bin -o models/ggml-large-v3.bin
```

Poi seleziona il modello dalle impostazioni.

## Sviluppo

```bash
# Build debug
swift build

# Esegui test
swift test

# Build release
swift build -c release
```

### Struttura del progetto

```
Sources/VoceInk/
  VoceInkApp.swift       # Entry point, MenuBarExtra UI
  AppState.swift          # Stato globale, orchestrazione flusso
  AudioRecorder.swift     # Registrazione audio AVFoundation (16kHz mono WAV)
  Transcriber.swift       # Integrazione whisper-cli (subprocess)
  TextProcessor.swift     # Post-processing italiano (libero + prompt-codex)
  TextInserter.swift      # Paste automatico via CGEvent + fallback clipboard
  HotKeyManager.swift     # Hotkey globale via Carbon API
  SettingsManager.swift   # Persistenza impostazioni (UserDefaults)
  SettingsView.swift      # Finestra impostazioni SwiftUI
```

## Terminali supportati

- Terminal.app
- iTerm2

Entrambi supportano Cmd+V per il paste. Se il paste automatico fallisce (es. permesso Accessibility mancante), il testo resta nella clipboard per incollarlo manualmente.

## Limiti noti

- **Prima trascrizione lenta**: il modello viene caricato in memoria al primo uso (~5-10s con medium)
- **No streaming**: la trascrizione avviene dopo aver fermato la registrazione, non in tempo reale
- **Terminologia tecnica**: il modello medium e buono ma non perfetto su gergo tecnico molto specifico. Il modello large-v3 e migliore
- **Post-processing rule-based**: corregge pattern comuni ma non errori semantici complessi
- **Accessibility obbligatoria**: senza il permesso Accessibility, il paste automatico non funziona (fallback: clipboard)

## Prossimi miglioramenti

- [ ] Feedback audio/visivo durante la registrazione (timer, livello audio)
- [ ] Supporto per modelli CoreML (trascrizione piu veloce)
- [ ] Shortcut personalizzabile con recorder visuale
- [ ] Supporto multilingue (rileva lingua automaticamente)
- [ ] Modalita streaming con trascrizione in tempo reale
- [ ] Integrazione diretta con whisper.cpp come libreria C (no subprocess)

## Privacy

VoceInk e progettata con la privacy come priorita:
- Tutto il processing avviene localmente sul tuo Mac
- L'audio registrato viene eliminato subito dopo la trascrizione
- Nessun dato viene inviato a server esterni
- Nessuna telemetria o analytics
- Il codice sorgente e interamente ispezionabile

## Licenza

MIT
