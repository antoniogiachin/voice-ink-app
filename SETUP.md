# Guida Setup - VoceInk

## Prerequisiti

Prima di iniziare, assicurati di avere:

1. **macOS 14+ (Sonoma)** su Apple Silicon (M1/M2/M3/M4)
2. **Xcode Command Line Tools**
   ```bash
   xcode-select --install
   ```
3. **Homebrew** (se non installato: https://brew.sh)
4. **cmake** via Homebrew
   ```bash
   brew install cmake
   ```

Verifica che tutto sia a posto:
```bash
uname -m          # deve stampare: arm64
swift --version   # deve stampare la versione di Swift
cmake --version   # deve stampare la versione di cmake
```

---

## Passo 1: Clona il repository

```bash
git clone https://github.com/antoniogiachin/voice-ink-app.git
cd voice-ink-app
```

---

## Passo 2: Setup whisper.cpp e modello

Questo script clona whisper.cpp, lo compila con supporto Metal (GPU Apple Silicon) e scarica il modello medium (~1.5 GB):

```bash
./scripts/setup.sh
```

Tempo stimato: 3-5 minuti (dipende dalla connessione per il download del modello).

Al termine vedrai:
```
=== Setup completato ===
  whisper-cli: .../whisper.cpp/build/bin/whisper-cli
  modello:     .../models/ggml-medium.bin
```

---

## Passo 3: Compila VoceInk

```bash
./scripts/build.sh
```

Al termine vedrai il path del bundle `.app` creato.

---

## Passo 4: Avvia l'app

```bash
open build/VoceInk.app
```

L'icona di VoceInk (microfono) apparira nella menu bar in alto a destra.

---

## Passo 5: Concedi i permessi

Al primo avvio macOS chiedera due permessi. Se non appaiono automaticamente, aggiungili manualmente:

### Microfono
**System Settings > Privacy & Security > Microphone** > attiva VoceInk

### Accessibilita (per il paste automatico)
**System Settings > Privacy & Security > Accessibility** > aggiungi VoceInk

Senza il permesso Accessibility il testo verra comunque copiato nella clipboard, ma dovrai incollarlo manualmente con Cmd+V.

---

## Passo 6: Usa VoceInk

1. Apri un terminale (Terminal.app o iTerm2)
2. Premi **Ctrl + Shift + Space** — l'icona diventa rossa (registrazione attiva)
3. Parla in italiano
4. Premi **Ctrl + Shift + Space** di nuovo — l'icona diventa arancione (trascrizione in corso)
5. Il testo trascritto appare nel terminale

### Cambiare modalita

Clicca sull'icona nella menu bar e seleziona:
- **Libero**: corregge solo punteggiatura e maiuscole
- **Prompt Codex**: rimuove filler ("ehm", "tipo", "cioe") e rende il testo piu operativo

---

## Risoluzione problemi

| Problema | Soluzione |
|----------|-----------|
| L'icona non appare nella menu bar | Verifica che l'app sia in esecuzione (`ps aux \| grep VoceInk`) |
| Hotkey non funziona | Controlla che nessun'altra app usi Ctrl+Shift+Space |
| "whisper-cli non trovato" | Riesegui `./scripts/setup.sh` |
| "Modello non trovato" | Verifica che `models/ggml-medium.bin` esista |
| Il paste non funziona | Concedi il permesso Accessibility (Passo 5) |
| Prima trascrizione lenta | Normale: il modello viene caricato in memoria al primo uso (~5-10s) |
| Trascrizione imprecisa | Prova il modello large-v3 per maggiore accuratezza (vedi sotto) |

### Usare un modello diverso

```bash
# Small (~500 MB, piu veloce)
curl -L https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin \
  -o models/ggml-small.bin

# Large v3 (~3 GB, piu preciso)
curl -L https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3.bin \
  -o models/ggml-large-v3.bin
```

Poi selezionalo dalle impostazioni (icona menu bar > Impostazioni).
