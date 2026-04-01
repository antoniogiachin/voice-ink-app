#!/usr/bin/env bash
set -euo pipefail

# Genera AppIcon.icns usando Swift per disegnare l'icona via CoreGraphics
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT="$PROJECT_DIR/resources/AppIcon.icns"

if [ -f "$OUTPUT" ]; then
    echo "[ok] AppIcon.icns gia' presente"
    exit 0
fi

echo "[..] Generazione AppIcon.icns..."

ICONSET_DIR=$(mktemp -d)/AppIcon.iconset
mkdir -p "$ICONSET_DIR"

# Script Swift inline per generare le PNG a varie dimensioni
swift - "$ICONSET_DIR" <<'SWIFT'
import AppKit

let outputDir = CommandLine.arguments[1]

func createIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        let ctx = NSGraphicsContext.current!.cgContext
        let s = CGFloat(size)

        // Sfondo gradient
        let colors = [
            CGColor(red: 0.92, green: 0.25, blue: 0.30, alpha: 1.0),
            CGColor(red: 0.65, green: 0.12, blue: 0.20, alpha: 1.0),
        ]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                   colors: colors as CFArray, locations: [0, 1])!

        let inset = s * 0.05
        let iconRect = rect.insetBy(dx: inset, dy: inset)
        let cornerRadius = s * 0.22
        let roundedPath = CGPath(roundedRect: iconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        ctx.addPath(roundedPath)
        ctx.clip()
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: rect.midX, y: rect.maxY),
                               end: CGPoint(x: rect.midX, y: rect.minY),
                               options: [])

        // Microfono bianco
        ctx.setFillColor(CGColor.white)
        ctx.setStrokeColor(CGColor.white)
        ctx.setLineCap(.round)

        let micW = s * 0.18
        let micH = s * 0.32
        let micX = rect.midX - micW / 2
        let micY = rect.midY + s * 0.02
        let micRect = CGRect(x: micX, y: micY, width: micW, height: micH)
        let micPath = CGPath(roundedRect: micRect, cornerWidth: micW / 2, cornerHeight: micW / 2, transform: nil)
        ctx.addPath(micPath)
        ctx.fillPath()

        // Arco supporto
        ctx.setLineWidth(s * 0.035)
        let arcY = micY + micH * 0.15
        let arcR = micW * 0.85
        ctx.addArc(center: CGPoint(x: rect.midX, y: arcY), radius: arcR,
                   startAngle: .pi * 0.15, endAngle: .pi * 0.85, clockwise: true)
        ctx.strokePath()

        // Stelo
        let stemTop = arcY - arcR
        let stemBottom = micY - micH * 0.12
        ctx.move(to: CGPoint(x: rect.midX, y: stemTop))
        ctx.addLine(to: CGPoint(x: rect.midX, y: stemBottom))
        ctx.strokePath()

        // Base
        let baseW = micW * 0.7
        ctx.move(to: CGPoint(x: rect.midX - baseW / 2, y: stemBottom))
        ctx.addLine(to: CGPoint(x: rect.midX + baseW / 2, y: stemBottom))
        ctx.strokePath()

        // Onde sonore piccole
        ctx.setLineWidth(s * 0.02)
        let waveCenter = CGPoint(x: rect.midX + micW / 2 + s * 0.02, y: micY + micH / 2)
        for i in 0..<2 {
            let r = (s * 0.06) + CGFloat(i) * (s * 0.055)
            ctx.addArc(center: waveCenter, radius: r,
                       startAngle: -.pi * 0.25, endAngle: .pi * 0.25, clockwise: false)
            ctx.strokePath()
        }

        return true
    }
    return image
}

let sizes: [(String, Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

for (name, size) in sizes {
    let icon = createIcon(size: size)
    guard let tiffData = icon.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Errore generazione \(name)")
        continue
    }
    let url = URL(fileURLWithPath: outputDir).appendingPathComponent("\(name).png")
    try! pngData.write(to: url)
}

print("PNG generate in \(outputDir)")
SWIFT

# Converti iconset in icns
iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT"
rm -rf "$(dirname "$ICONSET_DIR")"

echo "[ok] AppIcon.icns generata: $OUTPUT"
