// Renders the app icon into Aircon/Resources/Assets.xcassets/AppIcon.appiconset.
//   swift scripts/make-icon.swift
// The same motif as the panel: the wall unit with its flap open and air falling, on frosted night glass.
import AppKit
import SwiftUI

let night = Color(red: 0.043, green: 0.071, blue: 0.125)
let dusk = Color(red: 0.11, green: 0.18, blue: 0.33)
let glacierLight = Color(red: 0.56, green: 0.88, blue: 1.0)
let glacierDeep = Color(red: 0.18, green: 0.42, blue: 1.0)

struct Icon: View {
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 185, style: .continuous)
        ZStack {
            shape.fill(LinearGradient(colors: [dusk, night], startPoint: .top, endPoint: .bottom))
            shape.fill(RadialGradient(colors: [glacierDeep.opacity(0.55), .clear], center: UnitPoint(x: 0.5, y: 0.25), startRadius: 0, endRadius: 520))
            airflow
            unit.offset(y: -150)
            shape.strokeBorder(LinearGradient(colors: [.white.opacity(0.35), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom), lineWidth: 4)
        }
        .frame(width: 824, height: 824)
        .clipShape(shape)
        .shadow(color: .black.opacity(0.35), radius: 20, y: 10)
        .frame(width: 1024, height: 1024)
    }

    var unit: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 46, style: .continuous)
                .fill(LinearGradient(colors: [.white.opacity(0.95), Color(white: 0.78)], startPoint: .top, endPoint: .bottom))
                .overlay(alignment: .bottomTrailing) {
                    Circle().fill(glacierLight).frame(width: 22, height: 22).shadow(color: glacierLight, radius: 14).padding(.trailing, 44).padding(.bottom, 34)
                }
                .frame(width: 560, height: 150)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LinearGradient(colors: [Color(white: 0.85), Color(white: 0.6)], startPoint: .top, endPoint: .bottom))
                .frame(width: 520, height: 34)
                .rotation3DEffect(.degrees(-38), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.4)
                .offset(y: 4)
        }
        .shadow(color: .black.opacity(0.4), radius: 24, y: 12)
    }

    /// Fixed streaks fanning out below the flap, brighter near the unit.
    var airflow: some View {
        Canvas { context, size in
            let lanes: [(x: Double, start: Double, length: Double, width: Double)] = [
                (-0.30, 0.47, 0.20, 9), (-0.18, 0.52, 0.26, 12), (-0.06, 0.46, 0.30, 13),
                (0.06, 0.55, 0.24, 11), (0.18, 0.48, 0.28, 13), (0.30, 0.53, 0.20, 9),
                (-0.24, 0.74, 0.12, 7), (0.0, 0.80, 0.10, 8), (0.24, 0.76, 0.12, 7),
            ]
            for lane in lanes {
                let x0 = size.width * (0.5 + lane.x)
                let y0 = size.height * lane.start
                let y1 = y0 + size.height * lane.length
                var path = Path()
                path.move(to: CGPoint(x: x0, y: y0))
                path.addLine(to: CGPoint(x: x0 + lane.x * 70, y: y1))
                let shading = GraphicsContext.Shading.linearGradient(
                    Gradient(colors: [glacierLight.opacity(0.95), glacierDeep.opacity(0)]),
                    startPoint: CGPoint(x: x0, y: y0), endPoint: CGPoint(x: x0, y: y1)
                )
                context.stroke(path, with: shading, style: StrokeStyle(lineWidth: lane.width, lineCap: .round))
            }
        }
        .blendMode(.plusLighter)
    }
}

@MainActor func render() throws {
    let renderer = ImageRenderer(content: Icon())
    renderer.scale = 1
    guard let cgImage = renderer.cgImage else { fatalError("render failed") }
    let base = NSBitmapImageRep(cgImage: cgImage)
    let dir = URL(fileURLWithPath: "Aircon/Resources/Assets.xcassets/AppIcon.appiconset")
    var images: [[String: String]] = []
    for points in [16, 32, 128, 256, 512] {
        for scale in [1, 2] {
            let pixels = points * scale
            let name = "icon_\(points)x\(points)@\(scale)x.png"
            try resized(base, to: pixels).write(to: dir.appending(path: name))
            images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
        }
    }
    let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
    try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys]).write(to: dir.appending(path: "Contents.json"))
    try base.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "docs/icon-1024.png"))
}

func resized(_ image: NSBitmapImageRep, to pixels: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

try MainActor.assumeIsolated { try render() }
print("icon written")
