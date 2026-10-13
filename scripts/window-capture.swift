// Captures one app's panel window by id, never the whole screen (other windows can hold private data).
//   window-capture <owner name> <out.png>
import CoreGraphics
import Foundation

let owner = CommandLine.arguments[1], out = CommandLine.arguments[2]
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
let ids = list.filter { ($0[kCGWindowOwnerName as String] as? String) == owner && ($0[kCGWindowLayer as String] as? Int ?? 0) > 0 && (($0[kCGWindowBounds as String] as? [String: Double])?["Height"] ?? 0) > 100 }.compactMap { $0[kCGWindowNumber as String] as? Int }
guard let id = ids.first else { print("no window"); exit(1) }
let p = Process(); p.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture"); p.arguments = ["-x", "-o", "-l\(id)", out]; try! p.run(); p.waitUntilExit(); print("captured", id)
