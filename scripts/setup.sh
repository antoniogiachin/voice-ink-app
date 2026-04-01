#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WHISPER_DIR="$PROJECT_DIR/whisper.cpp"
MODELS_DIR="$PROJECT_DIR/models"
MODEL_NAME="ggml-medium.bin"

echo "=== VoceInk Setup ==="
echo ""

# 1. Clone whisper.cpp
if [ -d "$WHISPER_DIR" ]; then
    echo "[ok] whisper.cpp già presente in $WHISPER_DIR"
else
    echo "[..] Clonazione whisper.cpp..."
    git clone --depth 1 https://github.com/ggerganov/whisper.cpp.git "$WHISPER_DIR"
    echo "[ok] whisper.cpp clonato"
fi

# 2. Build whisper.cpp con supporto Metal + Accelerate (Apple Silicon)
BUILD_DIR="$WHISPER_DIR/build"
WHISPER_CLI="$BUILD_DIR/bin/whisper-cli"

if [ -f "$WHISPER_CLI" ]; then
    echo "[ok] whisper-cli già compilato: $WHISPER_CLI"
else
    echo "[..] Compilazione whisper.cpp (Metal + Accelerate)..."
    cmake -S "$WHISPER_DIR" -B "$BUILD_DIR" \
        -DCMAKE_BUILD_TYPE=Release \
        -DWHISPER_METAL=ON \
        -DWHISPER_ACCELERATE=ON \
        -DWHISPER_COREML=OFF \
        -DBUILD_SHARED_LIBS=OFF
    cmake --build "$BUILD_DIR" --config Release -j "$(sysctl -n hw.ncpu)"
    echo "[ok] whisper-cli compilato: $WHISPER_CLI"
fi

# 3. Download modello medium
mkdir -p "$MODELS_DIR"
MODEL_PATH="$MODELS_DIR/$MODEL_NAME"

if [ -f "$MODEL_PATH" ]; then
    echo "[ok] Modello già presente: $MODEL_PATH"
else
    echo "[..] Download modello $MODEL_NAME (~1.5 GB)..."
    curl -L --progress-bar \
        "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/$MODEL_NAME" \
        -o "$MODEL_PATH"
    echo "[ok] Modello scaricato: $MODEL_PATH"
fi

echo ""
echo "=== Setup completato ==="
echo "  whisper-cli: $WHISPER_CLI"
echo "  modello:     $MODEL_PATH"
echo ""
echo "Prossimo passo: ./scripts/build.sh"
