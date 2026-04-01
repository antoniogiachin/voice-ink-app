#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="VoceInk"
APP_BUNDLE="$PROJECT_DIR/build/$APP_NAME.app"

echo "=== VoceInk Build ==="
echo ""

# 1. Build con Swift Package Manager
echo "[..] Compilazione Swift (release)..."
cd "$PROJECT_DIR"
swift build -c release 2>&1
BINARY="$(swift build -c release --show-bin-path)/$APP_NAME"
echo "[ok] Binario: $BINARY"

# 2. Crea bundle .app
echo "[..] Creazione $APP_NAME.app..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$PROJECT_DIR/resources/Info.plist" "$APP_BUNDLE/Contents/"

# 3. Genera e copia icona app
"$SCRIPT_DIR/generate-icon.sh"
ICON_PATH="$PROJECT_DIR/resources/AppIcon.icns"
if [ -f "$ICON_PATH" ]; then
    cp "$ICON_PATH" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    echo "[ok] Icona app copiata nel bundle"
fi

# 4. Copia whisper-cli e modello dentro il bundle (opzionale, per portabilità)
WHISPER_CLI="$PROJECT_DIR/whisper.cpp/build/bin/whisper-cli"
MODEL_PATH="$PROJECT_DIR/models/ggml-medium.bin"

if [ -f "$WHISPER_CLI" ]; then
    cp "$WHISPER_CLI" "$APP_BUNDLE/Contents/Resources/whisper-cli"
    echo "[ok] whisper-cli copiato nel bundle"
fi

if [ -f "$MODEL_PATH" ]; then
    ln -s "$MODEL_PATH" "$APP_BUNDLE/Contents/Resources/ggml-medium.bin"
    echo "[ok] Modello linkato nel bundle (symlink)"
fi

echo ""
echo "=== Build completato ==="
echo "  $APP_BUNDLE"
echo ""
echo "Per avviare: open $APP_BUNDLE"
echo ""
echo "Nota: al primo avvio, concedi i permessi:"
echo "  - Microfono: System Settings > Privacy & Security > Microphone"
echo "  - Accessibilità: System Settings > Privacy & Security > Accessibility"
