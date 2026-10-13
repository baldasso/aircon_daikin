# Aircon

![Aircon](docs/appstore/screenshots/en/1.png)

A menu bar app for the Daikin split units sold in Brazil (the ones paired with the **Daikin Smart AC** app). It talks to them directly over the local network: no cloud, no account. English and Brazilian Portuguese. On the App Store as **Aircon for Daikin** (not affiliated with Daikin).

## How the units talk

Each unit announces itself over Bonjour as `_iota._tcp` and serves plain HTTP on port 15914:

- `GET /acstatus` returns the state; `POST /acstatus` changes it and returns the new state.
- Bodies are `base64(iv ‖ AES-128-CFB(json) ‖ crc16)`. Responses add one length byte after the IV; commands end their JSON with a literal `BZ`.
- The key is per unit. The Daikin app shows it under **Menu → Integrations → Home Assistant**.

This follows Daikin Brasil's own [Home Assistant integration](https://github.com/daikin-br/ha-custom-integration) and [crossworth/daikin](https://github.com/crossworth/daikin).

## Layout

| Path | What |
|---|---|
| `Packages/AirconKit` | Protocol, transport, discovery, storage and the observable `Home`/`Room` models. No UI. |
| `Aircon/App` | AppKit shell: status item, panel, launch options, wiring. |
| `Aircon/UI` | SwiftUI views. `Hero/` is the unit, airflow and ruler; `Design/` holds the tokens. |

## Build and install

Needs Xcode 27 and XcodeGen.

```sh
scripts/install.sh                      # test, build Release, install to /Applications
scripts/install.sh --import units.json  # …and add units to the keychain
```

`units.json` is `[{"name": "Living room", "host": "DAIKIN123ABC.local", "key": "…", "canHeat": false}]`. Units can also be added in the app, which checks each key against the unit and corrects look-alike characters.

Release builds are sandboxed (network client only); Debug builds are not, so they can read device files and the development switches below work.

## App Store

| Path | What |
|---|---|
| `docs/appstore/metadata.md` | Name, subtitle, keywords, descriptions (EN/PT), review notes, export compliance note |
| `docs/` | GitHub Pages site: [support](https://baldasso.github.io/aircon/support) and [privacy policy](https://baldasso.github.io/aircon/privacy) |
| `scripts/store-screenshots.sh` | Captures the panel (by window id) and composes the screenshots; needs an unlocked screen |
| `scripts/upload-to-app-store.sh` | `TEAM_ID=… scripts/upload-to-app-store.sh` archives, signs with your team and uploads |
| `scripts/make-icon.swift` | Regenerates the app icon |

## Accessibility

Every control has a VoiceOver label and state: the room tabs and modes say which is selected, swing/eco/powerful are toggles, and the temperature is a slider that also reads what the unit is doing ("21 degrees, cooling, room 24 degrees"). The menu bar icon says how many units are running. Arrow keys change the temperature, and Reduce Motion stops the airflow animation.

## Resource use

- With the panel closed: one status request per unit every 2 minutes, no animation, no timers otherwise.
- With the panel open: a refresh every 4 seconds; the airflow animation runs only while the selected unit is on.

## Development switches

| Variable | Effect |
|---|---|
| `AIRCON_DEMO=1` | Start in the demo (also available in the app). |
| `AIRCON_DEVICES_FILE=<path>` | Read units from a file instead of the keychain. |
| `AIRCON_SHOW=controls\|settings` | Open the panel on launch. |
| `AIRCON_ROOM=<name>` | Select that room first. |
| `AIRCON_ADD=<host>` | Open settings adding that unit. |
| `AIRCON_KEYCHAIN_SERVICE=<name>` | Use a separate keychain item (testing). |
| `AIRCON_LIVE=<path>` | Tests: also run against real units (reads all, nudges one setpoint and restores it). |

## Contributing

Issues and pull requests are welcome. If you have a unit that behaves differently (heat pumps, other Daikin lines on the same app), an issue with the model number and what you saw helps the most. **Never post your device keys.**

## License

[MIT](LICENSE). Aircon is an independent project, not affiliated with, endorsed by or sponsored by Daikin. Daikin is a trademark of Daikin Industries, Ltd.
