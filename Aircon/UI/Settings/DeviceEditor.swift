import AirconKit
import SwiftUI

/// Adds or edits one unit. A new or changed key is tried against the unit before anything is saved,
/// and look-alike characters (I/l/1, O/0) are corrected on the way.
struct DeviceEditor: View {
    @State private var draft: DeviceConfig
    @State private var check = CheckState.idle
    private let original: DeviceConfig
    let isNew: Bool
    let nearby: [DiscoveredDevice]
    let save: (DeviceConfig) -> Void
    let remove: (DeviceConfig.ID) -> Void

    enum CheckState: Equatable {
        case idle, checking, connected(roomTemperature: Double?), wrongKey, unreachable
    }

    init(
        device: DeviceConfig, isNew: Bool, nearby: [DiscoveredDevice],
        save: @escaping (DeviceConfig) -> Void,
        remove: @escaping (DeviceConfig.ID) -> Void
    ) {
        _draft = State(initialValue: device)
        original = device
        self.isNew = isNew
        self.nearby = nearby
        self.save = save
        self.remove = remove
    }

    private var unitID: String {
        let id = draft.host.trimmed.replacingOccurrences(of: ".local", with: "")
        return id.isEmpty ? "DAIKIN…" : id
    }

    private var canSubmit: Bool { !draft.name.trimmed.isEmpty && !draft.host.trimmed.isEmpty && !draft.key.trimmed.isEmpty }
    private var needsCheck: Bool { isNew || draft.key != original.key || draft.host != original.host }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    field("Unit") {
                        TextField("DAIKIN123ABC.local", text: $draft.host)
                            .fieldStyle()
                            .accessibilityLabel("Unit address")
                        nearbyChips
                    }
                    if needsCheck {
                        KeyGuide(unitID: unitID)
                    }
                    field("Key") {
                        TextField("Paste the device key", text: $draft.key)
                            .fieldStyle()
                            .accessibilityLabel("Device key")
                            .font(.system(size: 13, design: .monospaced))
                            .autocorrectionDisabled()
                    }
                    field("Name") {
                        TextField("Living room", text: $draft.name)
                            .fieldStyle()
                            .accessibilityLabel("Name")
                    }
                    heating
                    CheckMessage(state: check, unitID: unitID)
                }
                .padding(.bottom, 4)
            }
            .onChange(of: draft) { if check != .checking { check = .idle } }
            actions
        }
        .animation(Motion.settle, value: check)
    }

    @ViewBuilder
    private var nearbyChips: some View {
        let others = nearby.filter { $0.host != draft.host }
        if !others.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(others) { unit in
                        Button { draft.host = unit.host } label: {
                            Label(unit.id, systemImage: "dot.radiowaves.left.and.right")
                                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                                .foregroundStyle(Accent.glacier.light)
                                .padding(.horizontal, 9)
                                .frame(height: 24)
                                .background(Capsule().fill(Accent.glacier.deep.opacity(0.2)))
                        }
                        .buttonStyle(PressableStyle())
                        .accessibilityHint("Uses this unit's address")
                    }
                }
            }
        }
    }

    private var heating: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Heats too")
                    .font(Typeface.label)
                    .foregroundStyle(Ink.frost)
                Text("Leave off for units the Daikin app lists as cooling only.")
                    .font(Typeface.caption)
                    .foregroundStyle(Ink.mist)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityHidden(true)
            Spacer()
            Toggle("Heats too", isOn: $draft.canHeat)
                .labelsHidden()
                .accessibilityHint("Leave off for units the Daikin app lists as cooling only.")
                .toggleStyle(.switch)
                .controlSize(.small)
                .tint(Accent.glacier.deep)
        }
        .padding(12)
        .well(radius: 14)
    }

    private var actions: some View {
        VStack(spacing: 8) {
            Button(action: submit) {
                HStack(spacing: 8) {
                    if check == .checking {
                        ProgressView().controlSize(.small)
                    }
                    Text(needsCheck ? "Connect" : "Save changes")
                }
            }
            .buttonStyle(PrimaryButtonStyle(accent: .glacier))
            .disabled(!canSubmit || check == .checking)
            .opacity(canSubmit ? 1 : 0.45)

            if !isNew {
                Button("Remove unit") { remove(draft.id) }
                    .buttonStyle(SecondaryButtonStyle(tint: Accent.ember.light))
            }
        }
        .padding(.top, 10)
    }

    private func submit() {
        draft.name = draft.name.trimmed
        draft.host = draft.host.trimmed
        guard needsCheck else { return save(draft) }
        check = .checking
        Task {
            let outcome = await KeyCheck.run(draft.key, host: draft.host)
            await finish(outcome)
        }
    }

    private func finish(_ outcome: KeyCheck.Outcome) async {
        switch outcome {
        case .valid(let key, let state):
            draft.key = key
            check = .connected(roomTemperature: state.roomTemperature)
            AccessibilityNotification.Announcement(String(localized: "Connected.")).post()
            // Let the confirmation register before the editor goes away.
            try? await Task.sleep(for: .milliseconds(900))
            save(draft)
        case .wrongKey:
            check = .wrongKey
            AccessibilityNotification.Announcement(String(localized: "That key doesn't open \(unitID).")).post()
        case .unreachable:
            check = .unreachable
            AccessibilityNotification.Announcement(String(localized: "Couldn't reach \(unitID).")).post()
        }
    }

    private func field(_ title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle(title)
                .accessibilityHidden(true)  // each field carries its own label
            content()
        }
    }
}

private struct CheckMessage: View {
    let state: DeviceEditor.CheckState
    let unitID: String

    var body: some View {
        switch state {
        case .idle, .checking:
            EmptyView()
        case .connected(let room):
            Label {
                if let room {
                    Text("Connected. It's \(room.formatted(.number.precision(.fractionLength(0...1))))° in the room.")
                } else {
                    Text("Connected.")
                }
            } icon: {
                Image(systemName: "checkmark.circle.fill")
            }
            .font(Typeface.label)
            .foregroundStyle(Accent.lagoon.light)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        case .wrongKey:
            failure("That key doesn't open \(unitID). Copy it again from the Daikin Smart AC app with \(unitID) selected at the top.")
        case .unreachable:
            failure("Couldn't reach \(unitID). Check the address and that your Mac is on the same Wi-Fi as the unit.")
        }
    }

    private func failure(_ message: LocalizedStringKey) -> some View {
        Label { Text(message) } icon: { Image(systemName: "exclamationmark.circle.fill") }
            .font(Typeface.caption)
            .foregroundStyle(Accent.ember.light)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Where the key lives in the Daikin app. The steps are a real sequence, so they are numbered.
private struct KeyGuide: View {
    let unitID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Find the key on your phone")
                .font(Typeface.label)
                .foregroundStyle(Ink.frost)
                .accessibilityAddTraits(.isHeader)
            step(1, "Open the Daikin Smart AC app.")
            step(2, "Tap Menu, then Integrations, then Home Assistant.")
            step(3, "Choose \(unitID) at the top and copy the device key.")
            Text("Copy it on your iPhone and paste it here: Universal Clipboard carries it over.")
                .font(.system(size: 10.5))
                .foregroundStyle(Ink.mist.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Accent.glacier.deep.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Accent.glacier.light.opacity(0.18)))
    }

    private func step(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(number, format: .number)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Ink.night)
                .frame(width: 16, height: 16)
                .background(Circle().fill(Accent.glacier.light))
            Text(text)
                .font(Typeface.caption)
                .foregroundStyle(Ink.frost.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
