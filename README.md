# VoceInk

**Dettatura vocale locale per sviluppatori su macOS.**

VoceInk e un'app menu bar per macOS Apple Silicon che trasforma la tua voce in testo direttamente nel terminale. Usa [whisper.cpp](https://github.com/ggerganov/whisper.cpp) per la trascrizione, gira interamente sul tuo Mac e non invia nulla a nessun server.

Pensata per chi lavora con Codex, Claude CLI o qualunque tool a riga di comando e vuole dettare prompt, comandi e istruzioni senza toccare la tastiera.

**Zero cloud. Zero telemetria. Zero upload audio.**

---

## Come funziona

```
 Premi hotkey  →  Parla in italiano  →  Premi hotkey  →  Testo nel terminale
   (Ctrl+Shift+Space)                    (stop + trascrivi)
```

1. Premi **Ctrl + Shift + Space**: VoceInk inizia a registrare dal microfono (l'icona nella menu bar diventa rossa)
2. Parla in italiano — descrivi un prompt, detta un comando, spiega cosa vuoi fare
3. Premi di nuovo **Ctrl + Shift + Space**: la registrazione si ferma, whisper.cpp trascrive l'audio localmente
4. Il testo trascritto e pulito viene inserito automaticamente nel campo attivo del terminale

Tutto avviene sul tuo Mac. L'audio viene eliminato subito dopo la trascrizione.

---

## Perche VoceInk

- **100% locale**: nessun servizio cloud, nessuna API esterna, nessun account da creare
- **Ottimizzata per sviluppatori**: preserva path, nomi file, comandi shell, branch git, stack trace e token tecnici durante il post-processing
- **Due modalita di output**:
  - *Libero*: corregge solo punteggiatura e maiuscole, preserva il contenuto originale
  - *Prompt Codex*: rimuove filler ("ehm", "tipo", "cioe"), rende il testo piu chiaro e operativo per prompt di sviluppo
- **Integrazione terminale**: inserisce il testo direttamente dove stai lavorando (Terminal.app, iTerm2)
- **Privacy first**: nessuna telemetria, nessun analytics, audio cancellato subito

---

## Cosa preserva

Quando parli di codice, VoceInk riconosce e protegge automaticamente:

| Tipo | Esempio |
|------|---------|
| Path Unix | `/usr/bin/swift`, `~/Developer/progetto` |
| URL | `https://github.com/user/repo` |
| Nomi file | `package.json`, `main.swift`, `Dockerfile` |
| camelCase / PascalCase | `getUserName`, `AppDelegate` |
| snake_case | `user_name`, `MAX_RETRIES` |
| kebab-case | `my-component`, `feature-branch` |
| Backtick code | `` `git status` ``, `` `npm install` `` |
| Stack trace | `at Module.func (file:line)` |

---

## Requisiti

- macOS 14+ (Sonoma o successivo)
- Apple Silicon (M1/M2/M3/M4)
- Xcode Command Line Tools
- cmake (via Homebrew)
- ~2 GB di spazio disco

## Quick Start

```bash
git clone https://github.com/antoniogiachin/voice-ink-app.git
cd voice-ink-app
./scripts/setup.sh    # compila whisper.cpp + scarica modello (~1.5 GB)
./scripts/build.sh    # compila VoceInk
open build/VoceInk.app
```

Per la guida dettagliata passo-passo, permessi macOS e troubleshooting: **[SETUP.md](SETUP.md)**

---

## Architettura

```
┌─────────────────────────────────────┐
│       VoceInk (Menu Bar App)        │
│       SwiftUI · MenuBarExtra        │
├──────────┬──────────┬───────────────┤
│ HotKey   │ Audio    │  Settings     │
│ Manager  │ Recorder │  Manager      │
│ (Carbon) │(AVFound.)│ (UserDefaults)│
├──────────┴──────────┴───────────────┤
│          Transcriber                │
│    whisper.cpp CLI (subprocess)     │
├─────────────────────────────────────┤
│        TextProcessor                │
│   libero / prompt-codex (italiano)  │
├─────────────────────────────────────┤
│         TextInserter                │
│   CGEvent Cmd+V / fallback clipboard│
└─────────────────────────────────────┘
```

### Struttura del progetto

```
Sources/VoceInk/
  VoceInkApp.swift       # Entry point, MenuBarExtra UI
  AppState.swift          # Stato globale, orchestrazione flusso
  AudioRecorder.swift     # Registrazione audio (16kHz mono WAV)
  Transcriber.swift       # Integrazione whisper-cli
  TextProcessor.swift     # Post-processing italiano
  TextInserter.swift      # Paste automatico + fallback
  HotKeyManager.swift     # Hotkey globale (Carbon API)
  SettingsManager.swift   # Persistenza impostazioni
  SettingsView.swift      # Finestra impostazioni

Tests/VoceInkTests/       # 28 test unitari
scripts/                  # Setup e build automation
```

---

## Configurazione

Dall'icona nella menu bar o dalle Impostazioni (Cmd+,):

- **Modalita output**: Libero / Prompt Codex
- **Modello Whisper**: small (~500 MB), medium (~1.5 GB, default), large-v3 (~3 GB)
- **Hotkey**: default Ctrl+Shift+Space
- **Path whisper-cli**: override personalizzabile

---

## Sviluppo

```bash
swift build        # build debug
swift test         # esegui 28 test unitari
swift build -c release
```

---

## Limiti noti

- La prima trascrizione e piu lenta (~5-10s) perche il modello viene caricato in memoria
- Nessun supporto streaming: la trascrizione avviene dopo aver fermato la registrazione
- Il modello medium e buono ma non perfetto su terminologia tecnica molto specifica
- Il post-processing e rule-based: corregge pattern comuni, non errori semantici complessi
- Il paste automatico richiede il permesso Accessibility

## Roadmap

- [ ] Feedback visivo durante la registrazione (timer, livello audio)
- [ ] Modelli CoreML per trascrizione piu veloce
- [ ] Shortcut personalizzabile con recorder visuale
- [ ] Rilevamento automatico della lingua
- [ ] Streaming / trascrizione in tempo reale
- [ ] Integrazione whisper.cpp come libreria C (no subprocess)

---

## Privacy

- Tutto il processing avviene localmente sul tuo Mac
- L'audio registrato viene eliminato subito dopo la trascrizione
- Nessun dato viene inviato a server esterni
- Nessuna telemetria o analytics
- Codice sorgente interamente ispezionabile

## Licenza

MIT
