// Renders the layers of Aircon's Icon Composer icon (Aircon/Resources/AppIcon.icon) at 1024 px,
// on transparent canvases, so macOS can draw the default, dark, tinted and clear appearances:
//   swift scripts/make-icon-layers.swift Aircon/Resources/AppIcon.icon/Assets
// The motif is the panel's: the wall unit with its flap open, its indicator lit, and air falling.
// The night-blue body is the icon's own fill (icon.json).
import AppKit

let size: CGFloat = 1024
let glacier = NSColor(red: 0.56, green: 0.88, blue: 1.0, alpha: 1)

func render(_ name: String, _ draw: @escaping () -> Void) {
    let image = NSImage(size: NSSize(width: size, height: size), flipped: true) { _ in draw(); return true }
    let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(filePath: CommandLine.arguments[1]).appending(path: name))
}

// The casing and the open flap, opaque white: the icon gives them glass.
render("unit.png") {
    NSColor.white.setFill()
    NSBezierPath(roundedRect: NSRect(x: 212, y: 300, width: 600, height: 168), xRadius: 54, yRadius: 54).fill()
    // The flap, tilted open: a trapezoid hanging under the casing, narrower at its lip.
    let flap = NSBezierPath()
    flap.move(to: NSPoint(x: 252, y: 484))
    flap.line(to: NSPoint(x: 772, y: 484))
    flap.line(to: NSPoint(x: 756, y: 506))
    flap.line(to: NSPoint(x: 268, y: 506))
    flap.close()
    flap.lineJoinStyle = .round
    flap.lineWidth = 10
    NSColor.white.setStroke()
    flap.stroke()
    flap.fill()
}

// The indicator, lit in the cooling color.
render("indicator.png") {
    glacier.setFill()
    NSBezierPath(ovalIn: NSRect(x: 730, y: 412, width: 26, height: 26)).fill()
}

// The air: streaks fanning out below the flap, strongest near it.
render("air.png") {
    let lanes: [(x: CGFloat, start: CGFloat, length: CGFloat, width: CGFloat)] = [
        (-0.30, 560, 190, 14), (-0.18, 585, 250, 17), (-0.06, 555, 300, 18),
        (0.06, 600, 250, 17), (0.18, 565, 280, 18), (0.30, 590, 180, 14),
        (-0.24, 800, 110, 11), (0.0, 860, 90, 11), (0.24, 815, 100, 11),
    ]
    let context = NSGraphicsContext.current!.cgContext
    for lane in lanes {
        let x0 = size * (0.5 + lane.x)
        let x1 = x0 + lane.x * 110
        let y1 = lane.start + lane.length
        let path = CGMutablePath()
        path.move(to: CGPoint(x: x0, y: lane.start))
        path.addLine(to: CGPoint(x: x1, y: y1))
        context.saveGState()
        context.addPath(path.copy(strokingWithWidth: lane.width, lineCap: .round, lineJoin: .round, miterLimit: 1))
        context.clip()
        let gradient = CGGradient(colorsSpace: nil, colors: [glacier.cgColor, glacier.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 1])!
        context.drawLinearGradient(gradient, start: CGPoint(x: x0, y: lane.start), end: CGPoint(x: x1, y: y1), options: [])
        context.restoreGState()
    }
}
