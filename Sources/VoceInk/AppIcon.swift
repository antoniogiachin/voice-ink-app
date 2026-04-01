import AppKit

/// Genera le icone menu bar per VoceInk via CoreGraphics.
/// Template images: si adattano automaticamente a light/dark mode.
enum AppIcon {

    /// Microfono stilizzato per la menu bar (stato idle).
    static func menuBarIcon(size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let ctx = NSGraphicsContext.current!.cgContext
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.setStrokeColor(NSColor.black.cgColor)
            ctx.setLineWidth(1.2)
            ctx.setLineCap(.round)

            let midX = rect.midX
            let scale = size / 18.0

            // Corpo microfono (rettangolo arrotondato)
            let bodyW = 5.0 * scale
            let bodyH = 8.0 * scale
            let bodyX = midX - bodyW / 2
            let bodyY = 7.0 * scale
            let bodyRect = CGRect(x: bodyX, y: bodyY, width: bodyW, height: bodyH)
            let bodyPath = CGPath(roundedRect: bodyRect, cornerWidth: bodyW / 2, cornerHeight: bodyW / 2, transform: nil)
            ctx.addPath(bodyPath)
            ctx.fillPath()

            // Arco di supporto sotto il microfono
            let arcCenterY = 8.0 * scale
            let arcRadius = 5.5 * scale
            ctx.addArc(center: CGPoint(x: midX, y: arcCenterY), radius: arcRadius,
                       startAngle: .pi * 0.15, endAngle: .pi * 0.85, clockwise: true)
            ctx.strokePath()

            // Stelo verticale
            let stemTop = arcCenterY - arcRadius + 0.5 * scale
            let stemBottom = 2.5 * scale
            ctx.move(to: CGPoint(x: midX, y: stemTop))
            ctx.addLine(to: CGPoint(x: midX, y: stemBottom))
            ctx.strokePath()

            // Base orizzontale
            let baseW = 5.0 * scale
            ctx.move(to: CGPoint(x: midX - baseW / 2, y: stemBottom))
            ctx.addLine(to: CGPoint(x: midX + baseW / 2, y: stemBottom))
            ctx.strokePath()

            return true
        }
        image.isTemplate = true
        return image
    }

    /// Microfono con onde sonore (stato recording).
    static func menuBarRecordingIcon(size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let ctx = NSGraphicsContext.current!.cgContext
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.setStrokeColor(NSColor.black.cgColor)
            ctx.setLineCap(.round)

            let midX = rect.midX
            let scale = size / 18.0

            // Corpo microfono (più piccolo, spostato a sinistra per fare spazio alle onde)
            let offsetX = -2.0 * scale
            let bodyW = 4.5 * scale
            let bodyH = 7.0 * scale
            let bodyX = midX + offsetX - bodyW / 2
            let bodyY = 7.5 * scale
            let bodyRect = CGRect(x: bodyX, y: bodyY, width: bodyW, height: bodyH)
            let bodyPath = CGPath(roundedRect: bodyRect, cornerWidth: bodyW / 2, cornerHeight: bodyW / 2, transform: nil)
            ctx.addPath(bodyPath)
            ctx.fillPath()

            // Arco di supporto
            ctx.setLineWidth(1.0)
            let arcCenterY = 8.5 * scale
            let arcRadius = 5.0 * scale
            ctx.addArc(center: CGPoint(x: midX + offsetX, y: arcCenterY), radius: arcRadius,
                       startAngle: .pi * 0.15, endAngle: .pi * 0.85, clockwise: true)
            ctx.strokePath()

            // Stelo e base
            let stemTop = arcCenterY - arcRadius + 0.5 * scale
            let stemBottom = 2.5 * scale
            ctx.move(to: CGPoint(x: midX + offsetX, y: stemTop))
            ctx.addLine(to: CGPoint(x: midX + offsetX, y: stemBottom))
            ctx.strokePath()
            let baseW = 4.5 * scale
            ctx.move(to: CGPoint(x: midX + offsetX - baseW / 2, y: stemBottom))
            ctx.addLine(to: CGPoint(x: midX + offsetX + baseW / 2, y: stemBottom))
            ctx.strokePath()

            // Onde sonore (archi concentrici a destra del microfono)
            ctx.setLineWidth(1.0)
            let waveCenter = CGPoint(x: midX + offsetX + bodyW / 2 + 1.0 * scale, y: bodyY + bodyH / 2)
            for i in 0..<3 {
                let r = (3.0 + Double(i) * 2.5) * scale
                ctx.addArc(center: waveCenter, radius: r,
                           startAngle: -.pi * 0.3, endAngle: .pi * 0.3, clockwise: false)
                ctx.strokePath()
            }

            return true
        }
        image.isTemplate = true
        return image
    }

    /// Genera un'icona app (per Finder) usando SF Symbol mic.fill.
    static func appIcon(size: Int) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let ctx = NSGraphicsContext.current!.cgContext

            // Sfondo gradient circolare
            let colors = [
                CGColor(red: 0.9, green: 0.2, blue: 0.25, alpha: 1.0),
                CGColor(red: 0.7, green: 0.1, blue: 0.2, alpha: 1.0),
            ]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                       colors: colors as CFArray, locations: [0, 1])!

            // Rettangolo arrotondato (stile macOS icon)
            let inset = CGFloat(size) * 0.05
            let iconRect = rect.insetBy(dx: inset, dy: inset)
            let cornerRadius = CGFloat(size) * 0.22
            let roundedPath = CGPath(roundedRect: iconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
            ctx.addPath(roundedPath)
            ctx.clip()
            ctx.drawLinearGradient(gradient,
                                   start: CGPoint(x: rect.midX, y: rect.maxY),
                                   end: CGPoint(x: rect.midX, y: rect.minY),
                                   options: [])

            // Microfono bianco al centro
            ctx.setFillColor(CGColor.white)
            ctx.setStrokeColor(CGColor.white)

            let s = CGFloat(size)
            let micW = s * 0.2
            let micH = s * 0.35
            let micX = rect.midX - micW / 2
            let micY = rect.midY - micH * 0.15
            let micRect = CGRect(x: micX, y: micY, width: micW, height: micH)
            let micPath = CGPath(roundedRect: micRect, cornerWidth: micW / 2, cornerHeight: micW / 2, transform: nil)
            ctx.addPath(micPath)
            ctx.fillPath()

            // Arco supporto
            ctx.setLineWidth(s * 0.04)
            ctx.setLineCap(.round)
            let arcY = micY + micH * 0.15
            let arcR = micW * 0.9
            ctx.addArc(center: CGPoint(x: rect.midX, y: arcY), radius: arcR,
                       startAngle: .pi * 0.15, endAngle: .pi * 0.85, clockwise: true)
            ctx.strokePath()

            // Stelo e base
            let stemTop = arcY - arcR
            let stemBottom = micY - micH * 0.15
            ctx.move(to: CGPoint(x: rect.midX, y: stemTop))
            ctx.addLine(to: CGPoint(x: rect.midX, y: stemBottom))
            ctx.strokePath()
            let baseW = micW * 0.8
            ctx.move(to: CGPoint(x: rect.midX - baseW / 2, y: stemBottom))
            ctx.addLine(to: CGPoint(x: rect.midX + baseW / 2, y: stemBottom))
            ctx.strokePath()

            return true
        }
        return image
    }
}
