// Draws the Plume icon: swift tools/make-icon.swift && sh tools/make-icon.sh
import AppKit

let size: CGFloat = 1024
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()

let tile = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
NSGradient(colors: [NSColor(red: 0.20, green: 0.75, blue: 0.85, alpha: 1),
                    NSColor(red: 0.30, green: 0.22, blue: 0.75, alpha: 1)])!.draw(in: tile, angle: -55)

let ctx = NSGraphicsContext.current!.cgContext
ctx.saveGState()
ctx.translateBy(x: size / 2, y: size / 2)
ctx.rotate(by: -.pi / 4)   // tip toward top right
ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 30, color: NSColor.black.withAlphaComponent(0.3).cgColor)

// Half-width of the feather at height y (-250 base ... 290 tip).
func hw(_ y: CGFloat) -> CGFloat {
    let t = min(max((y + 290) / 640, 0), 1)
    return 125 * pow(sin(.pi * pow(t, 0.8)), 1.3)
}
let body = NSBezierPath()
body.move(to: NSPoint(x: 0, y: -290))
for i in 1...60 { let y = -290 + 640 * CGFloat(i) / 60; body.line(to: NSPoint(x: hw(y), y: y)) }
for i in stride(from: 59, through: 0, by: -1) { let y = -290 + 640 * CGFloat(i) / 60; body.line(to: NSPoint(x: -hw(y), y: y)) }
body.close()
NSColor.white.setFill()
body.fill()
ctx.setShadow(offset: .zero, blur: 0, color: nil)

let ink = NSColor(red: 0.30, green: 0.30, blue: 0.75, alpha: 0.5)
ink.setStroke()
for i in 0..<11 {
    let y = CGFloat(-220 + i * 52)
    for s in [-1.0, 1.0] {
        let end = y + 70, w = hw(end) - 14
        guard w > 12 else { continue }
        let p = NSBezierPath()
        p.lineWidth = 9; p.lineCapStyle = .round
        p.move(to: NSPoint(x: 0, y: y))
        p.line(to: NSPoint(x: CGFloat(s) * w, y: end))
        p.stroke()
    }
}
let tail = NSBezierPath()
tail.lineWidth = 17; tail.lineCapStyle = .round
tail.move(to: NSPoint(x: 0, y: -410)); tail.line(to: NSPoint(x: 0, y: -280))
NSColor.white.setStroke()
tail.stroke()
let quill = NSBezierPath()
quill.lineWidth = 13; quill.lineCapStyle = .round
quill.move(to: NSPoint(x: 0, y: -280)); quill.line(to: NSPoint(x: 0, y: 320))
NSColor(red: 0.30, green: 0.30, blue: 0.75, alpha: 0.85).setStroke()
quill.stroke()
ctx.restoreGState()
img.unlockFocus()

let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "tools/icon-1024.png"))
