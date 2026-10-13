import AirconKit
import AppIntents

/// A room as Siri and Shortcuts see it: just its name, resolved to the live `Room` when an intent runs.
struct RoomEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Room")
    static let defaultQuery = RoomQuery()

    let id: UUID
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    @MainActor
    init(_ room: Room) {
        id = room.id
        name = room.name
    }
}

/// What the intents act on. Set once at launch, before Siri can run anything; plain statics rather than
/// `@Dependency` so the intents can also be exercised outside a Siri request (see IntentSelfTest).
@MainActor
enum IntentContext {
    static var home: Home!
    static var library: DeviceLibrary!

    static func room(for entity: RoomEntity) throws -> Room {
        library.loadIfNeeded()
        guard let room = home.room(id: entity.id) else { throw RoomError.unreachable(entity.name) }
        return room
    }
}

struct RoomQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [RoomEntity] {
        rooms().filter { identifiers.contains($0.id) }
    }

    @MainActor
    func suggestedEntities() async throws -> [RoomEntity] {
        rooms()
    }

    /// "sala", "Sala" and "salá" all find "Sala".
    @MainActor
    func entities(matching string: String) async throws -> [RoomEntity] {
        let wanted = string.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        return rooms().filter {
            $0.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil).contains(wanted)
        }
    }

    @MainActor
    private func rooms() -> [RoomEntity] {
        IntentContext.library.loadIfNeeded()
        return IntentContext.home.rooms.map(RoomEntity.init)
    }
}

// AirconKit has no UI strings, so the spoken message for its error lives here.
extension RoomError: @retroactive CustomLocalizedStringResourceConvertible {
    public var localizedStringResource: LocalizedStringResource {
        switch self {
        case .unreachable(let name): "Couldn't reach \(name). Check that it has power and is on this Wi-Fi."
        }
    }
}
