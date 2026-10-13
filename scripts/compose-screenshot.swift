// Lays a captured panel onto a 16:10 App Store canvas with a headline.
//   swift scripts/compose-screenshot.swift <panel.png> <out.png> <headline> <subhead> [width]
// The canvas is 1280×800 by default (2560×1600 when the capture came from a Retina screen: pass 2560).
import AppKit
import SwiftUI

let arguments = CommandLine.arguments
guard arguments.count >= 5, let panel = NSImage(contentsOfFile: arguments[1]) else {
    FileHandle.standardError.write(Data("usage: compose-screenshot <panel.png> <out.png> <headline> <subhead> [width]\n".utf8))
    exit(1)
}
let output = URL(fileURLWithPath: arguments[2])
let headline = arguments[3]
let subhead = arguments[4]
let width = arguments.count > 5 ? Double(arguments[5]) ?? 1280 : 1280
let unit = width / 1280

struct Canvas: View {
    let panel: NSImage
    let headline: String
    let subhead: String
    let unit: Double

    let night = Color(red: 0.043, green: 0.071, blue: 0.125)
    let dusk = Color(red: 0.10, green: 0.16, blue: 0.30)
    let frost = Color(red: 0.93, green: 0.96, blue: 0.98)
    let mist = Color(red: 0.60, green: 0.65, blue: 0.72)
    let glacier = Color(red: 0.18, green: 0.42, blue: 1.0)

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [dusk, night], startPoint: .topTrailing, endPoint: .bottomLeading)
            RadialGradient(colors: [glacier.opacity(0.45), .clear], center: UnitPoint(x: 0.78, y: 0.1), startRadius: 0, endRadius: 620 * unit)

            // A sliver of menu bar, so the panel reads as dropping from it.
            Rectangle().fill(Color.white.opacity(0.07)).frame(height: 30 * unit)
            Image(systemName: "air.conditioner.horizontal.fill")
                .font(.system(size: 15 * unit))
                .foregroundStyle(frost)
                .position(x: 1280 * 0.735 * unit, y: 15 * unit)

            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 18 * unit) {
                    Text(headline)
                        .font(.system(size: 58 * unit, weight: .light, design: .serif))
                        .foregroundStyle(frost)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subhead)
                        .font(.system(size: 22 * unit))
                        .foregroundStyle(mist)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: 520 * unit, alignment: .leading)
                .padding(.leading, 110 * unit)
                Spacer()
            }
            .frame(maxHeight: .infinity)

            Image(nsImage: panel)
                .resizable()
                .interpolation(.high)
                .frame(width: panel.size.width * unit, height: panel.size.height * unit)
                .position(x: 1280 * 0.735 * unit, y: 42 * unit + panel.size.height * unit / 2)
        }
        .frame(width: 1280 * unit, height: 800 * unit)
    }
}

MainActor.assumeIsolated {
    let renderer = ImageRenderer(content: Canvas(panel: panel, headline: headline, subhead: subhead, unit: unit))
    renderer.scale = 1
    guard let image = renderer.cgImage,
          let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write(Data("render failed\n".utf8))
        exit(1)
    }
    try! png.write(to: output)
}
