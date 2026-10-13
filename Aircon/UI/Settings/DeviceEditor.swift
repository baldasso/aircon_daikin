import AirconKit
import SwiftUI

/// Name, network address and key for one unit. Units announcing themselves nearby can be picked instead of typed.
struct DeviceEditor: View {
    @State private var draft: DeviceConfig
    @State private var browser = DeviceBrowser()
    let isNew: Bool
    let save: (DeviceConfig) -> Void
    let remove: (DeviceConfig.ID) -> Void
    let cancel: () -> Void

    init(
        device: DeviceConfig, isNew: Bool,
        save: @escaping (DeviceConfig) -> Void,
        remove: @escaping (DeviceConfig.ID) -> Void,
        cancel: @escaping () -> Void
    ) {
        _draft = State(initialValue: device)
        self.isNew = isNew
        self.save = save
        self.remove = remove
        self.cancel = cancel
    }

    private var keyIsValid: Bool { draft.deviceKey != nil }
    private var canSave: Bool { !draft.name.trimmed.isEmpty && !draft.host.trimmed.isEmpty && keyIsValid }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            field("Name") {
                TextField("Living room", text: $draft.name)
                    .fieldStyle()
            }
            field("Unit") {
                TextField("DAIKIN123ABC.local", text: $draft.host)
                    .fieldStyle()
                nearbyUnits
            }
            field("Key") {
                SecureField("Paste the device key", text: $draft.key)
                    .fieldStyle()
                Text(keyHint)
                    .font(Typeface.caption)
                    .foregroundStyle(draft.key.isEmpty || keyIsValid ? Ink.mist : Accent.ember.light)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            actions
        }
        .onAppear { browser.start() }
        .onDisappear { browser.stop() }
    }

    private var keyHint: String {
        if draft.key.isEmpty || keyIsValid {
            return "In the Daikin Smart AC app: Menu → Integrations → Home Assistant."
        }
        return "This key isn't valid. Copy it again from the Daikin Smart AC app."
    }

    @ViewBuilder
    private var nearbyUnits: some View {
        let nearby = browser.found.filter { $0.host != draft.host }
        if !nearby.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(nearby) { unit in
                        Button { draft.host = unit.host } label: {
                            Label(unit.id, systemImage: "dot.radiowaves.left.and.right")
                                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                                .foregroundStyle(Accent.glacier.light)
                                .padding(.horizontal, 9)
                                .frame(height: 24)
                                .background(Capsule().fill(Accent.glacier.deep.opacity(0.2)))
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 8) {
            Button(isNew ? "Add unit" : "Save changes") {
                draft.name = draft.name.trimmed
                draft.host = draft.host.trimmed
                draft.key = draft.key.trimmed
                save(draft)
            }
            .buttonStyle(PrimaryButtonStyle(accent: .glacier))
            .disabled(!canSave)
            .opacity(canSave ? 1 : 0.45)

            if isNew {
                Button("Cancel", action: cancel)
                    .buttonStyle(SecondaryButtonStyle())
            } else {
                Button("Remove unit") { remove(draft.id) }
                    .buttonStyle(SecondaryButtonStyle(tint: Accent.ember.light))
            }
        }
    }

    private func field(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Ink.mist)
                .textCase(.uppercase)
                .tracking(0.6)
            content()
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
