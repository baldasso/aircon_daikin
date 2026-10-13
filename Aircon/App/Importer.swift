import AirconKit
import Foundation

/// `Aircon --import devices.json`: merges units into the registry, matching existing ones by host.
/// `--import -` reads standard input, which the sandbox allows when files elsewhere are off limits.
enum Importer {
    static func run(file: String, into registry: DeviceRegistry) {
        do {
            let data = file == "-"
                ? FileHandle.standardInput.readDataToEndOfFile()
                : try Data(contentsOf: URL(fileURLWithPath: file))
            let incoming = try JSONDecoder().decode([DeviceConfig].self, from: data)
            var devices = try registry.load()
            for unit in incoming {
                if let index = devices.firstIndex(where: { $0.host == unit.host }) {
                    devices[index].name = unit.name
                    devices[index].key = unit.key
                } else {
                    devices.append(unit)
                }
            }
            try registry.save(devices)
            print("Imported \(incoming.count) units; \(devices.count) saved.")
        } catch {
            FileHandle.standardError.write(Data("Import failed: \(error)\n".utf8))
        }
    }
}
